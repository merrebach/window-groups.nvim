-- Minimal, isolated Neovim config used to record the README demos.
-- Run through demo/record.sh, which sets NVIM_APPNAME so nothing touches your
-- own config, state or sessions.

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local deps = root .. "/demo/.deps"

local function dep(repo)
	local path = deps .. "/" .. repo:match("[^/]+$")
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/" .. repo, path })
	end
	vim.opt.rtp:prepend(path)
end

dep("nvim-tree/nvim-web-devicons")
dep("merrebach/singularity.nvim")
vim.opt.rtp:prepend(root)

vim.g.mapleader = " "
vim.o.termguicolors = true
vim.o.number = true
vim.o.signcolumn = "no"
vim.o.laststatus = 3
vim.o.showmode = false
vim.o.showcmd = false
vim.o.ruler = false
vim.o.shortmess = vim.o.shortmess .. "IFW"
vim.o.swapfile = false
vim.o.fillchars = "eob: "
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4

pcall(vim.cmd.colorscheme, "singularity")

-- Key caster: shows the pressed key and its action in the bottom-right corner,
-- so viewers can follow what happens in the recording.
local cast_buf, cast_win, cast_timer
local function cast(key, desc)
	local text = string.format("  %s  %s ", key, desc)
	if not (cast_buf and vim.api.nvim_buf_is_valid(cast_buf)) then
		cast_buf = vim.api.nvim_create_buf(false, true)
	end
	vim.api.nvim_buf_set_lines(cast_buf, 0, -1, false, { text })
	local width = vim.fn.strdisplaywidth(text)
	local cfg = {
		relative = "editor",
		anchor = "SE",
		row = vim.o.lines - 2,
		col = vim.o.columns - 1,
		width = width,
		height = 1,
		style = "minimal",
		border = "rounded",
		focusable = false,
		zindex = 250,
	}
	if cast_win and vim.api.nvim_win_is_valid(cast_win) then
		vim.api.nvim_win_set_config(cast_win, cfg)
	else
		cast_win = vim.api.nvim_open_win(cast_buf, false, cfg)
		vim.wo[cast_win].winhighlight = "Normal:PmenuSel,FloatBorder:PmenuSel"
	end
	if cast_timer then cast_timer:stop() end
	cast_timer = vim.defer_fn(function()
		if cast_win and vim.api.nvim_win_is_valid(cast_win) then
			vim.api.nvim_win_close(cast_win, true)
		end
		cast_win = nil
	end, 1500)
end

local function key(lhs, label, desc, fn)
	return { lhs, function() cast(label, desc) fn() end, desc = desc }
end

local wg = function() return require("window_groups") end

require("window_groups").setup({
	session = {
		autosave = vim.env.WG_DEMO_AUTOSAVE == "1",
		dir = vim.fn.stdpath("state") .. "/sessions",
	},
	keys = {
		key("<leader>q", "␣ q", "close buffer", function() wg().close_buf() end),
		key("<leader>bq", "␣ b q", "close group", function() wg().close_group() end),
		key("]b", "] b", "next buffer", function() wg().cycle("next") end),
		key("[b", "[ b", "prev buffer", function() wg().cycle("prev") end),
		key("<leader>bmh", "␣ b m h", "move buffer left", function() wg().move_buf("left") end),
		key("<leader>bmj", "␣ b m j", "move buffer down", function() wg().move_buf("down") end),
		key("<leader>bmk", "␣ b m k", "move buffer up", function() wg().move_buf("up") end),
		key("<leader>bml", "␣ b m l", "move buffer right", function() wg().move_buf("right") end),
		key("<leader>sl", "␣ s l", "split right", function() wg().split("right") end),
		key("<leader>sj", "␣ s j", "split down", function() wg().split("down") end),
	},
})

-- Window navigation with a visible cast as well.
for lhs, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	vim.keymap.set("n", "<C-" .. lhs .. ">", function()
		cast("Ctrl " .. lhs, "focus " .. dir)
		vim.cmd.wincmd(lhs)
	end)
end
