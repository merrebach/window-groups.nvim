local M = {}

function M.load(path)
	local f = io.open(path, "r")
	if not f then return {} end
	local data = vim.json.decode(f:read("*a"))
	f:close()
	return data
end

function M.save(path, todos)
	local f = assert(io.open(path, "w"))
	f:write(vim.json.encode(todos))
	f:close()
end

return M
