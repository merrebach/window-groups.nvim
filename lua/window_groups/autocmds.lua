local M = {}

function M.setup()
	local groups = require("window_groups")
	local aug = vim.api.nvim_create_augroup("WindowGroups", { clear = true })

	vim.api.nvim_create_autocmd("WinNew", {
		group = aug,
		callback = function()
			local win = vim.api.nvim_get_current_win()
			pcall(vim.api.nvim_win_set_var, win, "group_bufs", {})
		end,
	})

	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = aug,
		callback = function(ev)
			local buf = ev.buf
			if not groups.eligible(buf) then return end
			local win = ev.win or vim.api.nvim_get_current_win()
			if not groups.is_editor_win(win) then return end
			local owner = groups.find_owner(buf)
			if owner and owner ~= win and vim.api.nvim_win_is_valid(owner) then
				local restore = groups.last_buf(win)
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(win) and restore and vim.api.nvim_buf_is_valid(restore) then
						vim.api.nvim_win_set_buf(win, restore)
					end
					if vim.api.nvim_win_is_valid(owner) then
						vim.api.nvim_set_current_win(owner)
					end
				end)
				return
			end
			groups.add(win, buf)
		end,
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		group = aug,
		callback = function(ev)
			local win = tonumber(ev.match)
			if not win then return end
			-- vim.w is cleared when window dies; nothing to free here.
			-- Reserved for future cleanup (e.g., wiping orphaned bufs).
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = aug,
		callback = function(ev)
			local buf = ev.buf
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win) then
					local ok, list = pcall(vim.api.nvim_win_get_var, win, "group_bufs")
					if ok and type(list) == "table" then
						for i = #list, 1, -1 do
							if list[i] == buf then table.remove(list, i) end
						end
						pcall(vim.api.nvim_win_set_var, win, "group_bufs", list)
					end
				end
			end
		end,
	})
end

return M
