-- Minimal init for plenary test runner
-- CI: nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {sequential = true}"

local plenary_path = vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
if not vim.loop.fs_stat(plenary_path) then
	vim.fn.system({
		"git", "clone", "--depth=1",
		"https://github.com/nvim-lua/plenary.nvim",
		plenary_path,
	})
end
vim.opt.rtp:prepend(plenary_path)
vim.opt.rtp:prepend(".")
vim.cmd("runtime! plugin/**/*.vim plugin/**/*.lua")
