local async = require "luau-lsp.async"

local M = {}

function M.it_async(name, block)
  local env = getfenv(2)
  return env.it(name, function()
    local res
    async.run(block, function(...)
      res = vim.F.pack_len(...)
    end)
    vim.wait(5000, function()
      return res ~= nil
    end)
    if res[1] then
      error(res[1])
    end
  end)
end

return M
