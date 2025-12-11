local async = require "plenary.async"
local util = require "luau-lsp.util"

describe("util.download_file", function()
  local download_file = async.wrap(util.download_file, 3)

  it(
    "should download a file from a valid URL",
    async.util.will_block(function()
      local url = "https://google.com"
      local temp_path = vim.fn.tempname()

      local err, path = download_file(url, temp_path)
      assert.is_nil(err)
      assert.is_equal(temp_path, path)
      vim.fn.delete(temp_path)
    end)
  )
end)
