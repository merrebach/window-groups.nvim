local M = {}

function M.render(todos)
	for i, todo in ipairs(todos) do
		local mark = todo.done and "x" or " "
		print(string.format("%2d [%s] %s", i, mark, todo.title))
	end
end

return M
