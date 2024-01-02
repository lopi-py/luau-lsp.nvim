local Path = require "plenary.path"

local M = {}
M.on_windows = vim.loop.os_uname().sysname == "Windows_NT"

function M.plugin_path()
  return Path:new(debug.getinfo(1).source:sub(2)):parent():parent():parent()
end

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

function M.parser_revision()
  return (M.plugin_path() / "parser.revision"):read()
end

function M.get_query(query_type)
  return (M.plugin_path() / "_queries" / "luau" / (query_type .. ".scm")):read()
end

return M
