local async = require "luau-lsp.async"

local M = {}

---@return string
function M.temp_file()
  local path = vim.fn.tempname()
  vim.fn.writefile({}, path)

  local env = getfenv(2)
  env.finally(function()
    vim.fn.delete(path)
  end)

  return path
end

---@param name string
---@param block async fun()
function M.it_async(name, block)
  local env = getfenv(2)
  return env.it(name, function()
    ---@type [string?, unknown ...]
    local result
    async.run(block, function(...)
      result = vim.F.pack_len(...)
    end)

    assert(
      vim.wait(5000, function()
        return result ~= nil
      end),
      "async test timed out"
    )

    if result[1] then
      error(result[1], 0)
    end
  end)
end

return M
