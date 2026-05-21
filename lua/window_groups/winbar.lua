local M = {}

local _icon_hl_cache = {}
vim.api.nvim_create_autocmd("ColorScheme", { callback = function() _icon_hl_cache = {} end })

local function blended_icon_hl(icon_hl, bg_hl)
	local key = icon_hl .. "\0" .. bg_hl
	if _icon_hl_cache[key] then return _icon_hl_cache[key] end
	local name = "WindowGroupsIcon_" .. icon_hl:gsub("[^%w]", "_") .. "_" .. bg_hl
	local icon_attrs = vim.api.nvim_get_hl(0, { name = icon_hl, link = false })
	local bg_attrs   = vim.api.nvim_get_hl(0, { name = bg_hl,   link = false })
	vim.api.nvim_set_hl(0, name, { fg = icon_attrs.fg, bg = bg_attrs.bg })
	_icon_hl_cache[key] = name
	return name
end

local function get_icon(buf)
	local config = require("window_groups").config

	if config.get_icon then
		return config.get_icon(buf)
	end

	local name = vim.api.nvim_buf_get_name(buf)
	local fname = vim.fn.fnamemodify(name, ":t")
	local ext   = vim.fn.fnamemodify(name, ":e")

	local ok_dev, devicons = pcall(require, "nvim-web-devicons")
	if ok_dev then
		local icon, hl = devicons.get_icon(fname, ext, { default = true })
		return icon or "", hl
	end

	local ok_mini, mini_icons = pcall(require, "mini.icons")
	if ok_mini then
		local icon, hl = mini_icons.get("file", fname)
		return icon or "", hl
	end

	return "", nil
end

local function basename(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then return "[No Name]" end
	return vim.fn.fnamemodify(name, ":t")
end

function M.render()
	local groups = require("window_groups")
	local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(win) then return "" end
	local buf = vim.api.nvim_win_get_buf(win)
	if not groups.eligible(buf) then return "" end
	local current_win = vim.api.nvim_get_current_win()
	local is_active_win = win == current_win
	local list = groups.list(win)
	if #list == 0 then return "" end
	local parts = {}
	for i, b in ipairs(list) do
		if vim.api.nvim_buf_is_valid(b) then
			local is_current_buf = b == buf
			local hl_name
			if is_current_buf and is_active_win then
				hl_name = "GroupsActive"
			elseif is_current_buf then
				hl_name = "GroupsCurrent"
			else
				hl_name = "GroupsInactive"
			end
			local icon, icon_hl = get_icon(b)
			local bname = basename(b)
			local modified = vim.bo[b].modified and " ●" or ""
			local icon_seg
			if icon_hl and icon_hl ~= "" and hl_name ~= "GroupsInactive" then
				local bhl = blended_icon_hl(icon_hl, hl_name)
				icon_seg = "%#" .. bhl .. "#" .. icon .. "%#" .. hl_name .. "#"
			else
				icon_seg = icon
			end
			local seg = string.format(" %d ", i) .. icon_seg .. string.format(" %s%s ", bname, modified)
			table.insert(parts, "%#" .. hl_name .. "#" .. seg)
		end
	end
	return table.concat(parts, "%#GroupsSep#│") .. "%#GroupsFill#"
end

return M
