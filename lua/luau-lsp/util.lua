local Path = require "plenary.path"

local M = {}
M.on_windows = vim.loop.os_uname().sysname == "Windows_NT"

function M.plugin_path()
  return Path:new(debug.getinfo(1).source:sub(2)):parent():parent():parent()
end

function M.storage_file(key)
  return tostring(M.plugin_path() / "storage" / key)
end

function M.parser_revision()
  return (M.plugin_path() / "parser.revision"):read()
end

function M.get_query(query_type)
  return (M.plugin_path() / "_queries" / "luau" / (query_type .. ".scm")):read()
end

return M
