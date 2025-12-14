local async = require "luau-lsp.async"
local util = require "luau-lsp.util"

local function wait(fn, timeout)
  return function()
    local res
    async.run(fn, function(...)
      res = vim.F.pack_len(...)
    end)
    vim.wait(timeout or 5000, function()
      return res ~= nil
    end)
    if res[1] then
      error(res[1])
    end
    return unpack(res, 2, res.n)
  end
end

describe("util.request", function()
  it(
    "should return an error for an invalid URL",
    wait(function()
      local url = "https://invalid.url.test/doesnotexist"

      local err, res = async.await(util.request, url, nil)
      assert.is_string(err)
      assert.is_nil(res)
    end)
  )

  it(
    "should download a file from a valid URL",
    wait(function()
      local url = "https://google.com"
      local path = vim.fn.tempname()

      local err, res = async.await(util.request, url, { output = path })
      assert.is_nil(err)
      assert.is_true(util.is_file(path))
      assert.equal("", res.body)

      vim.fn.delete(path)
    end)
  )
end)
