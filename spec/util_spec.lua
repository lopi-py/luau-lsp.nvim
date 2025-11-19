local async = require "luau-lsp.async"
local test_util = require "spec.test_util"
local util = require "luau-lsp.util"

local it_async = test_util.it_async

describe("util.limit_table_depth", function()
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
    assert.equal(10, count_nested_depth(tbl))
    assert.equal(5, count_nested_depth(result))
  end)

  it("allows mpack encoding of deeply nested tables", function()
    local tbl = create_nested(50)
    local result = util.limit_table_depth(tbl, 30)

    local success, encoded = pcall(vim.mpack.encode, result)
    assert.is_true(success)
    assert.is_true(#encoded > 0)

    local decoded = vim.mpack.decode(encoded)
    assert.equal(50, decoded.value)
  end)
end)

describe("util.request", function()
  it_async("should return an error for an invalid URL", function()
    local url = "https://invalid.url.test/doesnotexist"

    local err, res = async.await(util.request, url, nil)
    assert.is_string(err)
    assert.is_nil(res)
  end)

  it_async("should download a file from a valid URL", function()
    local url = "https://google.com"
    local path = vim.fn.tempname()

    local err, res = async.await(util.request, url, { output = path })
    assert.is_nil(err)
    assert.is_true(util.is_file(path))
    assert.equal("", res.body)

    vim.fn.delete(path)
  end)
end)
