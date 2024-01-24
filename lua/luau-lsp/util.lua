local Path = require "plenary.path"

local M = {}

function M.storage_file(key)
  local storage = Path:new(vim.fn.stdpath "data") / "luau-lsp"
  storage:mkdir()

  return tostring(storage / key)
end

---@param amount number
---@param callback function
---@return function
function M.fcounter(amount, callback)
  local counter = 0
  return function()
    counter = counter + 1
    if counter == amount then
      callback()
    end
  end
end

---@param t table
---@param value any
---@return boolean
function M.list_contains(t, value)
  for _, v in ipairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

return M
