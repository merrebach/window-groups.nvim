-- window-groups.nvim
-- See CONTEXT.md and docs/adr/0001-window-scoped-groups.md

local M = {}

local BASE_EXCLUDE = { "neo-tree", "snacks_dashboard", "dashboard" }

M.config = {
	exclude_filetypes = {},
	winbar = true,
	get_icon = nil,
	highlights = {
		active   = {},
		current  = {},
		inactive = {},
		sep      = {},
		fill     = {},
	},
}

local _exclude_set = {}

local function build_exclude_set()
	_exclude_set = {}
	for _, ft in ipairs(BASE_EXCLUDE) do _exclude_set[ft] = true end
	for _, ft in ipairs(M.config.exclude_filetypes) do _exclude_set[ft] = true end
end

local function get_list(win)
	win = win or vim.api.nvim_get_current_win()
	local ok, list = pcall(vim.api.nvim_win_get_var, win, "group_bufs")
	if not ok or type(list) ~= "table" then
		list = {}
		pcall(vim.api.nvim_win_set_var, win, "group_bufs", list)
	end
	return list, win
end

local function set_list(win, list)
	pcall(vim.api.nvim_win_set_var, win, "group_bufs", list)
end

local function index_of(list, buf)
	for i, b in ipairs(list) do
		if b == buf then return i end
	end
	return nil
end

local function buf_valid(buf)
	return buf and vim.api.nvim_buf_is_valid(buf)
end

function M.eligible(buf)
	if not buf_valid(buf) then return false end
	if vim.bo[buf].buftype ~= "" then return false end
	if not vim.bo[buf].buflisted then return false end
	if _exclude_set[vim.bo[buf].filetype] then return false end
	return true
end

function M.is_editor_win(win)
	if not vim.api.nvim_win_is_valid(win) then return false end
	local cfg = vim.api.nvim_win_get_config(win)
	if cfg.relative ~= "" then return false end
	local buf = vim.api.nvim_win_get_buf(win)
	if vim.bo[buf].buftype ~= "" then return false end
	if _exclude_set[vim.bo[buf].filetype] then return false end
	return true
end

function M.find_owner(buf)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local list = get_list(win)
		if index_of(list, buf) then return win end
	end
	return nil
end

function M.list(win)
	return get_list(win)
end

function M.last_buf(win)
	local list = get_list(win)
	for i = #list, 1, -1 do
		if buf_valid(list[i]) then return list[i] end
	end
	return nil
end

function M.add(win, buf)
	if not M.eligible(buf) then return end
	if not M.is_editor_win(win) then return end
	local list = get_list(win)
	if index_of(list, buf) then return end
	table.insert(list, buf)
	set_list(win, list)
end

function M.remove(win, buf)
	local list = get_list(win)
	local idx = index_of(list, buf)
	if not idx then return end
	table.remove(list, idx)
	set_list(win, list)
end

local function pick_neighbor_buf(list, removed_idx)
	if #list == 0 then return nil end
	return list[math.min(removed_idx, #list)]
end

function M.close_buf()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	if not M.eligible(buf) then
		pcall(vim.cmd, "bdelete")
		return
	end
	local list = get_list(win)
	local idx = index_of(list, buf)
	if not idx then
		pcall(vim.cmd, "bdelete " .. buf)
		return
	end
	table.remove(list, idx)
	set_list(win, list)
	local next_buf = pick_neighbor_buf(list, idx)
	if next_buf and buf_valid(next_buf) then
		vim.api.nvim_win_set_buf(win, next_buf)
		pcall(vim.api.nvim_buf_delete, buf, { force = false })
	else
		pcall(vim.api.nvim_buf_delete, buf, { force = false })
		if #vim.api.nvim_tabpage_list_wins(0) > 1 and vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, false)
		end
	end
end

function M.close_group()
	local win = vim.api.nvim_get_current_win()
	if not M.is_editor_win(win) then return end
	local list = vim.deepcopy(get_list(win))
	set_list(win, {})
	for _, buf in ipairs(list) do
		if buf_valid(buf) then pcall(vim.api.nvim_buf_delete, buf, { force = false }) end
	end
	if #vim.api.nvim_tabpage_list_wins(0) > 1 and vim.api.nvim_win_is_valid(win) then
		pcall(vim.api.nvim_win_close, win, false)
	end
end

function M.cycle(direction)
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	local list = get_list(win)
	local valid = vim.tbl_filter(buf_valid, list)
	if #valid ~= #list then
		set_list(win, valid)
		list = valid
	end
	if #list < 2 then return end
	local idx = index_of(list, buf)
	if not idx then
		vim.api.nvim_win_set_buf(win, list[1])
		return
	end
	local step = direction == "next" and 1 or -1
	local new_idx = ((idx - 1 + step) % #list) + 1
	vim.api.nvim_win_set_buf(win, list[new_idx])
end

local DIR_TO_WINCMD = { h = "h", j = "j", k = "k", l = "l" }

function M.move_buf(direction)
	local wincmd = DIR_TO_WINCMD[direction]
	if not wincmd then return end
	local from_win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(from_win)
	if not M.eligible(buf) then
		vim.notify("window-groups: current buffer not eligible", vim.log.levels.WARN)
		return
	end
	local from_list = get_list(from_win)
	local from_idx = index_of(from_list, buf)
	if not from_idx then
		vim.notify("window-groups: buffer not in current group", vim.log.levels.WARN)
		return
	end
	local cur = from_win
	vim.cmd("wincmd " .. wincmd)
	local to_win = vim.api.nvim_get_current_win()
	if to_win == cur then
		vim.notify("window-groups: no neighbor window " .. direction, vim.log.levels.WARN)
		return
	end
	if not M.is_editor_win(to_win) then
		vim.notify("window-groups: neighbor not an editor window", vim.log.levels.WARN)
		vim.api.nvim_set_current_win(from_win)
		return
	end
	table.remove(from_list, from_idx)
	set_list(from_win, from_list)
	local replacement = pick_neighbor_buf(from_list, from_idx)
	if replacement and buf_valid(replacement) then
		vim.api.nvim_win_set_buf(from_win, replacement)
	else
		local scratch = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(from_win, scratch)
	end
	local to_list = get_list(to_win)
	if not index_of(to_list, buf) then
		table.insert(to_list, buf)
		set_list(to_win, to_list)
	end
	vim.api.nvim_win_set_buf(to_win, buf)
	vim.api.nvim_set_current_win(to_win)
end

function M.split(direction)
	local src_win = vim.api.nvim_get_current_win()
	if not M.is_editor_win(src_win) then
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if M.is_editor_win(win) then
				vim.api.nvim_set_current_win(win)
				src_win = win
				break
			end
		end
	end
	local cmd = ({
		h = "leftabove vnew",
		l = "rightbelow vnew",
		k = "leftabove new",
		j = "rightbelow new",
	})[direction]
	if not cmd then return end
	local buf = vim.api.nvim_win_get_buf(src_win)
	vim.cmd(cmd)
	local new_win = vim.api.nvim_get_current_win()
	local scratch_buf = vim.api.nvim_win_get_buf(new_win)
	set_list(new_win, {})
	if M.eligible(buf) then
		local src_list = get_list(src_win)
		local src_idx = index_of(src_list, buf)
		if src_idx then
			table.remove(src_list, src_idx)
			set_list(src_win, src_list)
			local replacement = pick_neighbor_buf(src_list, src_idx)
			if replacement and buf_valid(replacement) then
				vim.api.nvim_win_set_buf(src_win, replacement)
			else
				local s = vim.api.nvim_create_buf(false, true)
				vim.bo[s].bufhidden = "wipe"
				vim.api.nvim_win_set_buf(src_win, s)
			end
		end
		set_list(new_win, { buf })
		vim.api.nvim_win_set_buf(new_win, buf)
		if scratch_buf ~= buf and vim.api.nvim_buf_is_valid(scratch_buf) then
			pcall(vim.api.nvim_buf_delete, scratch_buf, { force = true })
		end
	else
		vim.bo[scratch_buf].buflisted = false
		vim.bo[scratch_buf].bufhidden = "wipe"
	end
end

function M.seed_current_window()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	if M.eligible(buf) and M.is_editor_win(win) then
		M.add(win, buf)
	end
end

local function setup_default_highlights(hl_opts)
	local function get_hl(name)
		return vim.api.nvim_get_hl(0, { name = name, link = false })
	end
	local tablinesel = get_hl("TabLineSel")
	local tabline    = get_hl("TabLine")
	local comment    = get_hl("Comment")
	local normal     = get_hl("Normal")
	local fallbacks = {
		GroupsActive   = { bg = tablinesel.bg, fg = normal.fg or tablinesel.fg },
		GroupsCurrent  = { bg = tabline.bg, fg = tabline.fg },
		GroupsInactive = { bg = tabline.bg, fg = comment.fg or tabline.fg },
		GroupsSep      = { bg = tabline.bg, fg = comment.fg or tabline.fg },
		GroupsFill     = { bg = tabline.bg },
	}
	local overrides = {
		GroupsActive   = hl_opts.active,
		GroupsCurrent  = hl_opts.current,
		GroupsInactive = hl_opts.inactive,
		GroupsSep      = hl_opts.sep,
		GroupsFill     = hl_opts.fill,
	}
	for group, fallback in pairs(fallbacks) do
		local override = overrides[group] or {}
		if vim.fn.hlexists(group) == 0 then
			vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", fallback, override))
		elseif next(override) ~= nil then
			local existing = get_hl(group)
			vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", existing, override))
		end
	end
end

local _setup_done = false

function M.setup(opts)
	if _setup_done then return end
	_setup_done = true

	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)
	build_exclude_set()

	require("window_groups.autocmds").setup()

	if M.config.winbar then
		vim.o.winbar = "%{%v:lua.require'window_groups.winbar'.render()%}"
	end

	local aug = vim.api.nvim_create_augroup("WindowGroupsHighlights", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = aug,
		callback = function()
			setup_default_highlights(M.config.highlights)
		end,
	})
	setup_default_highlights(M.config.highlights)

	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		if M.eligible(buf) and M.is_editor_win(win) then
			M.add(win, buf)
		end
	end
end

return M
