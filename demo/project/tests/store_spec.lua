local store = require("app.store")

describe("store", function()
	it("returns an empty list for a missing file", function()
		assert.same({}, store.load("does-not-exist.json"))
	end)
end)
