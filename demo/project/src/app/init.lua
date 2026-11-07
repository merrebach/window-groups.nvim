local store = require("app.store")
local view = require("app.view")

local M = {}

function M.run(args)
	local todos = store.load(args.file or "todos.json")
	view.render(todos)
end

return M
