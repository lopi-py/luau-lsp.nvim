local lspconfig = require "lspconfig"

local path = lspconfig.util.path
local group = vim.api.nvim_create_augroup("luau-lsp", { clear = true })

local M = {
  on_windows = vim.loop.os_uname().version:match "Windows",
}

function M.storage_path(key)
  return path.join(
    path.dirname(path.dirname(path.dirname(debug.getinfo(1).source:sub(2)))),
    "storage",
    key
  )
end

function M.autocmd(event, opts)
  opts.group = opts.group or group

  vim.api.nvim_create_autocmd(event, opts)
end

--- Utility for multiple async functions
---@param count number
---@param callback function
function M.make_on_finish(count, callback)
  local current_count = 0
  return function(...)
    current_count = current_count + 1
    if current_count == count then
      callback(...)
    end
  end
end

return M
