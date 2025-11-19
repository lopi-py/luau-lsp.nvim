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

  describe("limit_table_depth", function()
    local function create_nested(depth)
      if depth <= 0 then
        return { value = depth }
      end
      return { value = depth, child = create_nested(depth - 1) }
    end

    local function count_nested_depth(tbl)
      local current = tbl
      local count = 0
      while current and current.child do
        current = current.child
        count = count + 1
      end
      return count
    end

    it("preserves shallow tables", function()
      local tbl = create_nested(3)
      local result = util.limit_table_depth(tbl, 10)
      assert.same(create_nested(3), result)
    end)

    it("truncates tables at max depth", function()
      local tbl = create_nested(10)
      local result = util.limit_table_depth(tbl, 5)
      assert.equals(10, count_nested_depth(tbl))
      assert.equals(5, count_nested_depth(result))
    end)

    it("allows mpack encoding of deeply nested tables", function()
      local tbl = create_nested(50)
      local result = util.limit_table_depth(tbl, 30)

      local success, encoded = pcall(vim.mpack.encode, result)
      assert.is_true(success)
      assert.is_true(#encoded > 0)

      local decoded = vim.mpack.decode(encoded)
      assert.equals(50, decoded.value)
    end)
  end)
end)
