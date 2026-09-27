-- window-groups.nvim session persistence
-- See docs/adr/0003-session-persistence.md

local M = {}

M.VERSION = 1

-- Pure helpers ---------------------------------------------------------------

function M.encode(state)
	return vim.json.encode(state)
end

function M.decode(str)
	local ok, state = pcall(vim.json.decode, str)
	if not ok or type(state) ~= "table" then
		return nil, "invalid payload"
	end
	if state.version ~= M.VERSION then
		return nil, "unsupported version: " .. tostring(state.version)
	end
	if type(state.tabs) ~= "table" then
		return nil, "missing tabs"
	end
	return state
end

-- Long-bracket level whose closing delimiter does not occur in `str`.
function M.bracket_level(str)
	local level = 0
	while str:find("]" .. ("="):rep(level) .. "]", 1, true) do
		level = level + 1
	end
	return level
end

-- Assigns saved groups to restored windows.
-- `groups`:  list of { current = path, bufs = { path, ... } }
-- `windows`: list of { win = winid, name = displayed path }
-- Returns a map winid -> group. Matches by displayed file first (unique per
-- tabpage thanks to single-membership), then pairs leftovers in order.
function M.plan_restore(groups, windows)
	local plan = {}
	local used_group, used_win = {}, {}
	local win_by_name = {}
	for i, w in ipairs(windows) do
		if w.name ~= "" and not win_by_name[w.name] then
			win_by_name[w.name] = i
		end
	end
	for gi, group in ipairs(groups) do
		local wi = group.current and win_by_name[group.current]
		if wi and not used_win[wi] then
			plan[windows[wi].win] = group
			used_group[gi], used_win[wi] = true, true
		end
	end
	local wi = 1
	for gi, group in ipairs(groups) do
		if not used_group[gi] then
			while wi <= #windows and used_win[wi] do wi = wi + 1 end
			if wi > #windows then break end
			plan[windows[wi].win] = group
			used_win[wi] = true
		end
	end
	return plan
end

-- Neovim side ----------------------------------------------------------------

local function buf_path(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then return nil end
	return vim.fn.fnamemodify(name, ":p")
end

local function editor_windows(tabpage)
	local groups = require("window_groups")
	return vim.tbl_filter(groups.is_editor_win, vim.api.nvim_tabpage_list_wins(tabpage))
end

local function capture_tab(tabpage)
	local groups = require("window_groups")
	local saved = {}
	for _, win in ipairs(editor_windows(tabpage)) do
		local bufs = {}
		for _, buf in ipairs(groups.list(win)) do
			local path = vim.api.nvim_buf_is_valid(buf) and buf_path(buf)
			if path then table.insert(bufs, path) end
		end
		if #bufs > 0 then
			table.insert(saved, {
				current = buf_path(vim.api.nvim_win_get_buf(win)),
				bufs = bufs,
			})
		end
	end
	return { groups = saved }
end

function M.capture(tab_scoped)
	local tabpages = tab_scoped and { vim.api.nvim_get_current_tabpage() } or vim.api.nvim_list_tabpages()
	local state = { version = M.VERSION, tab_scoped = tab_scoped, tabs = {} }
	local any = false
	for _, tabpage in ipairs(tabpages) do
		local tab = capture_tab(tabpage)
		if #tab.groups > 0 then any = true end
		table.insert(state.tabs, tab)
	end
	return state, any
end

-- Resets every Group in `tabpage` and seeds each editor Window with the Buffer
-- it displays. Used after a session load so windows are never left groupless.
local function seed_tab(tabpage)
	local groups = require("window_groups")
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
		pcall(vim.api.nvim_win_set_var, win, "group_bufs", {})
	end
	for _, win in ipairs(editor_windows(tabpage)) do
		groups.add(win, vim.api.nvim_win_get_buf(win))
	end
end

function M.seed_all()
	for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		seed_tab(tabpage)
	end
end

local function resolve_bufs(paths)
	local skip_missing = require("window_groups").config.session.skip_missing
	local bufs = {}
	for _, path in ipairs(paths) do
		if not skip_missing or vim.fn.filereadable(path) == 1 then
			local buf = vim.fn.bufadd(path)
			vim.bo[buf].buflisted = true
			table.insert(bufs, buf)
		end
	end
	return bufs
end

local function apply_tab(tabpage, saved_tab)
	local groups = require("window_groups")
	seed_tab(tabpage)
	local windows = {}
	for _, win in ipairs(editor_windows(tabpage)) do
		table.insert(windows, { win = win, name = buf_path(vim.api.nvim_win_get_buf(win)) or "" })
	end
	local plan = M.plan_restore(saved_tab.groups or {}, windows)
	for win, group in pairs(plan) do
		local bufs = resolve_bufs(group.bufs or {})
		local shown = vim.api.nvim_win_get_buf(win)
		if groups.eligible(shown) and not vim.tbl_contains(bufs, shown) then
			table.insert(bufs, shown)
		end
		vim.api.nvim_win_set_var(win, "group_bufs", bufs)
	end
end

function M.apply(state)
	local tabpages = state.tab_scoped and { vim.api.nvim_get_current_tabpage() } or vim.api.nvim_list_tabpages()
	for i, tabpage in ipairs(tabpages) do
		local saved_tab = state.tabs[i]
		if saved_tab then apply_tab(tabpage, saved_tab) end
	end
	vim.cmd("redrawstatus!")
end

-- Entry point called from the line appended to Session.vim.
function M.restore(payload)
	local state, err = M.decode(payload)
	if not state then
		vim.notify("window-groups: cannot restore groups (" .. err .. ")", vim.log.levels.WARN)
		return
	end
	M.apply(state)
end

function M.payload_line(state)
	local json = M.encode(state)
	local eq = ("="):rep(M.bracket_level(json))
	return string.format(
		'silent! lua pcall(function() require("window_groups.session").restore([%s[%s]%s]) end)',
		eq, json, eq
	)
end

-- Appends the group payload to the session file just written by :mksession.
function M.append_to(path)
	if not path or path == "" then return end
	local tab_scoped = not vim.tbl_contains(vim.opt.sessionoptions:get(), "tabpages")
	local state, any = M.capture(tab_scoped)
	if not any then return end
	local f = io.open(path, "a")
	if not f then return end
	f:write(M.payload_line(state), "\n")
	f:close()
end

-- Per-cwd session management -------------------------------------------------

-- Session file name for `cwd`, e.g. "/home/me/proj" -> "%home%me%proj.vim".
function M.encode_cwd(cwd)
	return cwd:gsub("[\\/]+$", ""):gsub("[\\/:]", "%%") .. ".vim"
end

-- Directory whose session a startup should restore, or nil. A bare `nvim`
-- restores `cwd`; `nvim <dir>` (e.g. `nvim .`) restores `<dir>`; anything else
-- opens files and restores nothing.
function M.startup_dir(args, cwd, is_dir)
	if #args == 0 then return cwd end
	if #args == 1 and is_dir(args[1]) then return args[1] end
	return nil
end

-- Autoload only for a startup_dir() start in a UI with nothing opened yet and
-- a stored session for that directory.
function M.should_autoload(ctx)
	return ctx.dir ~= nil and not ctx.stdin and ctx.has_ui and not ctx.has_content and ctx.exists
end

local function cfg()
	return require("window_groups").config.session
end

function M.path(cwd)
	return cfg().dir .. "/" .. M.encode_cwd(cwd or vim.fn.getcwd())
end

local function is_dir_buf(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	return name ~= "" and vim.fn.isdirectory(name) == 1
end

-- True when any tabpage has an editor Window showing an Eligible Buffer with a
-- file name, i.e. there is something worth saving. Directory buffers (netrw
-- after `nvim .`) do not count.
function M.has_content()
	local groups = require("window_groups")
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if groups.is_editor_win(win) then
			local buf = vim.api.nvim_win_get_buf(win)
			if groups.eligible(buf) and vim.api.nvim_buf_get_name(buf) ~= "" and not is_dir_buf(buf) then
				return true
			end
		end
	end
	return false
end

-- Wipes directory buffers no window shows, left over from `nvim <dir>`.
local function wipe_hidden_dir_bufs()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_dir_buf(buf) and #vim.fn.win_findbuf(buf) == 0 then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
	end
end

-- Set by delete() so the next exit does not immediately recreate the session.
local _autosave_paused = false

local function notify(msg, level)
	vim.notify("window-groups: " .. msg, level or vim.log.levels.INFO)
end

function M.save(opts)
	opts = opts or {}
	if not M.has_content() then
		if not opts.silent then notify("nothing to save", vim.log.levels.WARN) end
		return false
	end
	local path = M.path()
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	local saved_opts = vim.o.sessionoptions
	vim.o.sessionoptions = cfg().options
	local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(path))
	vim.o.sessionoptions = saved_opts
	if not ok then
		notify("saving session failed: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	_autosave_paused = false
	if not opts.silent then notify("session saved") end
	return true
end

function M.load(opts)
	opts = opts or {}
	local dir = opts.dir or vim.fn.getcwd()
	local path = M.path(dir)
	if vim.fn.filereadable(path) == 0 then
		if not opts.silent then notify("no session for " .. dir, vim.log.levels.WARN) end
		return false
	end
	local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(path))
	if not ok then
		notify("loading session failed: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	wipe_hidden_dir_bufs()
	return true
end

function M.delete()
	local path = M.path()
	if vim.fn.filereadable(path) == 0 then
		notify("no session for " .. vim.fn.getcwd(), vim.log.levels.WARN)
		return false
	end
	vim.fn.delete(path)
	_autosave_paused = true
	notify("session deleted")
	return true
end

-- Autosave on exit, unless the session was deleted in this Neovim instance and
-- not saved again since.
function M.autosave()
	if _autosave_paused or #vim.api.nvim_list_uis() == 0 then return false end
	return M.save({ silent = true })
end

local _stdin = false

function M.autoload_context()
	local is_dir = function(path) return vim.fn.isdirectory(path) == 1 end
	local dir = M.startup_dir(vim.fn.argv(-1, -1), vim.fn.getcwd(), is_dir)
	if dir then dir = vim.fn.fnamemodify(dir, ":p") end
	return {
		dir = dir,
		stdin = _stdin,
		has_ui = #vim.api.nvim_list_uis() > 0,
		has_content = M.has_content(),
		exists = dir ~= nil and vim.fn.filereadable(M.path(dir)) == 1,
	}
end

function M.autoload(ctx)
	ctx = ctx or M.autoload_context()
	if M.should_autoload(ctx) then
		M.load({ dir = ctx.dir, silent = true })
	end
end

local SUBCOMMANDS = {
	save = function() M.save() end,
	load = function() M.load() end,
	delete = function() M.delete() end,
}

local function setup_command()
	vim.api.nvim_create_user_command("WindowGroupsSession", function(args)
		local fn = SUBCOMMANDS[args.args]
		if not fn then
			notify("unknown subcommand '" .. args.args .. "' (save|load|delete)", vim.log.levels.ERROR)
			return
		end
		fn()
	end, {
		nargs = 1,
		desc = "Save, load or delete the window-groups session of the cwd",
		complete = function(lead)
			return vim.tbl_filter(function(name)
				return name:find(lead, 1, true) == 1
			end, vim.tbl_keys(SUBCOMMANDS))
		end,
	})
end

local function setup_autosave(aug)
	vim.api.nvim_create_autocmd("StdinReadPre", {
		group = aug,
		callback = function() _stdin = true end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = aug,
		-- nested: :mksession must trigger SessionWritePost to append the Groups.
		nested = true,
		callback = function() M.autosave() end,
	})
	if vim.v.vim_did_enter == 1 then
		-- Plugin was lazy-loaded after startup: VimEnter already fired.
		M.autoload()
	else
		vim.api.nvim_create_autocmd("VimEnter", {
			group = aug,
			nested = true,
			callback = function() M.autoload() end,
		})
	end
end

function M.setup()
	local aug = vim.api.nvim_create_augroup("WindowGroupsSession", { clear = true })
	setup_command()
	if cfg().autosave then setup_autosave(aug) end
	vim.api.nvim_create_autocmd("SessionWritePost", {
		group = aug,
		callback = function() M.append_to(vim.v.this_session) end,
	})
	-- Runs before the appended payload line; covers sessions without payload.
	vim.api.nvim_create_autocmd("SessionLoadPost", {
		group = aug,
		callback = function() M.seed_all() end,
	})
end

return M
