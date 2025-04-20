local util = require "luau-lsp.util"

describe("utilities", function()
  it("calls the callback only on the n-th call", function()
    local ran = false
    local fn = util.on_count(function()
      ran = true
    end, 3)

    fn()
    fn()
    assert.is_false(ran)
    fn()
    assert.is_true(ran)
  end)
end)
