local Path = require "plenary.path"
local group = vim.api.nvim_create_augroup("luau-lsp", { clear = true })

local M = {
  on_windows = vim.loop.os_uname().version:match "Windows",
}

function M.plugin_path()
  return Path:new(debug.getinfo(1).source:sub(2)):parent():parent():parent()
end

function M.storage_file(key)
  return tostring(M.plugin_path() / "storage" / key)
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
