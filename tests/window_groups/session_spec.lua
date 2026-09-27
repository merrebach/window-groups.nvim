local wg = require("window_groups")
local session = require("window_groups.session")

pcall(function()
	wg.setup({})
end)

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")

local function file(name)
	local path = tmp .. "/" .. name
	vim.fn.writefile({ name }, path)
	return path
end

local function names(win)
	return vim.tbl_map(function(b)
		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t")
	end, wg.list(win))
end

local function reset_editor()
	vim.cmd("silent! tabonly!")
	vim.cmd("silent! only!")
	vim.cmd("enew!")
	vim.cmd("silent! %bwipeout!")
	vim.api.nvim_win_set_var(0, "group_bufs", {})
end

describe("decode()", function()
	it("rejects invalid json", function()
		assert.is_nil((session.decode("{nope")))
	end)

	it("rejects unknown version", function()
		assert.is_nil((session.decode(vim.json.encode({ version = 99, tabs = {} }))))
	end)

	it("accepts current version", function()
		local state = session.decode(vim.json.encode({ version = session.VERSION, tabs = {} }))
		assert.is_table(state)
	end)
end)

describe("bracket_level()", function()
	it("returns 0 when no closing bracket present", function()
		assert.equals(0, session.bracket_level('{"a":1}'))
	end)

	it("skips levels whose delimiter occurs in the string", function()
		assert.equals(2, session.bracket_level("x]]y]=]z"))
	end)
end)

describe("plan_restore()", function()
	it("matches groups by displayed file regardless of order", function()
		local g1 = { current = "/a", bufs = { "/a" } }
		local g2 = { current = "/b", bufs = { "/b" } }
		local plan = session.plan_restore({ g1, g2 }, {
			{ win = 10, name = "/b" },
			{ win = 11, name = "/a" },
		})
		assert.equals(g2, plan[10])
		assert.equals(g1, plan[11])
	end)

	it("falls back to window order for unmatched groups", function()
		local g1 = { current = "/gone", bufs = { "/x" } }
		local g2 = { current = "/b", bufs = { "/b" } }
		local plan = session.plan_restore({ g1, g2 }, {
			{ win = 10, name = "/b" },
			{ win = 11, name = "" },
		})
		assert.equals(g2, plan[10])
		assert.equals(g1, plan[11])
	end)

	it("drops groups when there are fewer windows", function()
		local plan = session.plan_restore(
			{ { current = "/a", bufs = { "/a" } }, { current = "/b", bufs = { "/b" } } },
			{ { win = 10, name = "/a" } }
		)
		assert.equals(1, vim.tbl_count(plan))
	end)
end)

describe(":mksession round trip", function()
	local a, b, c, d = file("a.lua"), file("b.lua"), file("c.lua"), file("d.lua")
	local session_file = tmp .. "/Session.vim"

	before_each(reset_editor)

	it("restores groups of split windows", function()
		vim.cmd("edit " .. a)
		vim.cmd("edit " .. b)
		local left = vim.api.nvim_get_current_win()
		vim.cmd("rightbelow vsplit " .. c)
		local right = vim.api.nvim_get_current_win()
		vim.cmd("edit " .. d)
		vim.api.nvim_win_set_var(left, "group_bufs", { vim.fn.bufnr(a), vim.fn.bufnr(b) })
		vim.api.nvim_win_set_var(right, "group_bufs", { vim.fn.bufnr(c), vim.fn.bufnr(d) })

		vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
		reset_editor()
		vim.cmd("source " .. vim.fn.fnameescape(session_file))

		local wins = vim.api.nvim_tabpage_list_wins(0)
		assert.equals(2, #wins)
		assert.same({ "a.lua", "b.lua" }, names(wins[1]))
		assert.same({ "c.lua", "d.lua" }, names(wins[2]))
		assert.is_true(vim.bo[vim.fn.bufnr(a)].buflisted)
	end)

	it("restores groups per tabpage", function()
		vim.cmd("edit " .. a)
		vim.api.nvim_win_set_var(0, "group_bufs", { vim.fn.bufnr(a) })
		vim.cmd("tabedit " .. b)
		vim.cmd("edit " .. c)
		vim.api.nvim_win_set_var(0, "group_bufs", { vim.fn.bufnr(b), vim.fn.bufnr(c) })

		vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
		reset_editor()
		vim.cmd("source " .. vim.fn.fnameescape(session_file))

		local tabs = vim.api.nvim_list_tabpages()
		assert.equals(2, #tabs)
		assert.same({ "a.lua" }, names(vim.api.nvim_tabpage_list_wins(tabs[1])[1]))
		assert.same({ "b.lua", "c.lua" }, names(vim.api.nvim_tabpage_list_wins(tabs[2])[1]))
	end)

	it("skips files deleted since the session was saved", function()
		local gone = file("gone.lua")
		vim.cmd("edit " .. gone)
		vim.cmd("edit " .. a)
		vim.api.nvim_win_set_var(0, "group_bufs", { vim.fn.bufnr(gone), vim.fn.bufnr(a) })

		vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
		reset_editor()
		vim.fn.delete(gone)
		vim.cmd("source " .. vim.fn.fnameescape(session_file))

		assert.same({ "a.lua" }, names(vim.api.nvim_get_current_win()))
	end)

	it("seeds groups from displayed buffers for sessions without payload", function()
		vim.cmd("edit " .. a)
		vim.api.nvim_win_set_var(0, "group_bufs", {})

		vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
		reset_editor()
		vim.cmd("source " .. vim.fn.fnameescape(session_file))

		assert.same({ "a.lua" }, names(vim.api.nvim_get_current_win()))
	end)
end)

describe("encode_cwd()", function()
	it("turns path separators into % and appends .vim", function()
		assert.equals("%home%me%proj.vim", session.encode_cwd("/home/me/proj"))
	end)

	it("ignores trailing separators", function()
		assert.equals("%home%me%proj.vim", session.encode_cwd("/home/me/proj/"))
	end)
end)

describe("should_autoload()", function()
	local base = { argc = 0, stdin = false, has_ui = true, has_content = false, exists = true }

	it("loads on a bare start with a stored session", function()
		assert.is_true(session.should_autoload(base))
	end)

	for key, value in pairs({ argc = 1, stdin = true, has_ui = false, has_content = true, exists = false }) do
		it("does not load when " .. key .. " = " .. tostring(value), function()
			assert.is_false(session.should_autoload(vim.tbl_extend("force", base, { [key] = value })))
		end)
	end
end)

describe("per-cwd sessions", function()
	local a, b = file("pa.lua"), file("pb.lua")

	before_each(function()
		reset_editor()
		wg.config.session.dir = tmp .. "/sessions"
		vim.fn.delete(wg.config.session.dir, "rf")
	end)

	it("save() writes the cwd session including groups, load() restores it", function()
		vim.cmd("edit " .. a)
		vim.cmd("edit " .. b)
		vim.api.nvim_win_set_var(0, "group_bufs", { vim.fn.bufnr(a), vim.fn.bufnr(b) })

		assert.is_true(session.save({ silent = true }))
		assert.equals(1, vim.fn.filereadable(session.path()))

		reset_editor()
		assert.is_true(session.load({ silent = true }))
		assert.same({ "pa.lua", "pb.lua" }, names(vim.api.nvim_get_current_win()))
	end)

	it("save() keeps the user's sessionoptions", function()
		vim.cmd("edit " .. a)
		vim.o.sessionoptions = "blank,help"
		session.save({ silent = true })
		assert.equals("blank,help", vim.o.sessionoptions)
	end)

	it("save() refuses to overwrite with an empty editor", function()
		assert.is_false(session.save({ silent = true }))
		assert.equals(0, vim.fn.filereadable(session.path()))
	end)

	it("load() returns false without a stored session", function()
		assert.is_false(session.load({ silent = true }))
	end)

	it("delete() removes the stored session", function()
		vim.cmd("edit " .. a)
		session.save({ silent = true })
		assert.is_true(session.delete())
		assert.equals(0, vim.fn.filereadable(session.path()))
	end)

	it("autoload() loads the session when the context allows it", function()
		vim.cmd("edit " .. a)
		vim.api.nvim_win_set_var(0, "group_bufs", { vim.fn.bufnr(a) })
		session.save({ silent = true })
		reset_editor()

		session.autoload({ argc = 0, stdin = false, has_ui = true, has_content = false, exists = true })
		assert.same({ "pa.lua" }, names(vim.api.nvim_get_current_win()))
	end)

	it(":WindowGroupsSession dispatches subcommands", function()
		vim.cmd("edit " .. a)
		vim.cmd("WindowGroupsSession save")
		assert.equals(1, vim.fn.filereadable(session.path()))
		vim.cmd("WindowGroupsSession delete")
		assert.equals(0, vim.fn.filereadable(session.path()))
	end)

	it(":WindowGroupsSession completes subcommands", function()
		local got = vim.fn.getcompletion("WindowGroupsSession ", "cmdline")
		table.sort(got)
		assert.same({ "delete", "load", "save" }, got)
	end)
end)

describe("autosave switch", function()
	local function count(event)
		return #vim.api.nvim_get_autocmds({ group = "WindowGroupsSession", event = event })
	end

	after_each(function()
		wg.config.session.autosave = false
		session.setup()
	end)

	it("registers no autosave autocmds when off", function()
		wg.config.session.autosave = false
		session.setup()
		assert.equals(0, count("VimLeavePre"))
	end)

	it("registers autosave on exit when on", function()
		wg.config.session.autosave = true
		session.setup()
		assert.equals(1, count("VimLeavePre"))
	end)

	it("autosave on exit appends the groups payload", function()
		reset_editor()
		wg.config.session.dir = tmp .. "/sessions"
		vim.fn.delete(wg.config.session.dir, "rf")
		vim.cmd("edit " .. file("exit.lua"))
		wg.config.session.autosave = true
		session.setup()
		local list_uis = vim.api.nvim_list_uis
		vim.api.nvim_list_uis = function() return { {} } end
		local ok, err = pcall(vim.api.nvim_exec_autocmds, "VimLeavePre", { group = "WindowGroupsSession" })
		vim.api.nvim_list_uis = list_uis
		assert(ok, err)
		local content = table.concat(vim.fn.readfile(session.path()), "\n")
		assert.truthy(content:find("window_groups.session", 1, true))
	end)

	it("keeps the :mksession hook regardless of the switch", function()
		wg.config.session.autosave = false
		session.setup()
		assert.equals(1, count("SessionWritePost"))
	end)
end)
