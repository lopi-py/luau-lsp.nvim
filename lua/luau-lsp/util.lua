local Path = require "plenary.path"
local a = require "plenary.async"

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

function M.parser_revision()
  return (M.plugin_path() / "parser.revision"):read()
end

function M.get_query(query_type)
  return (M.plugin_path() / "queries" / "luau" / (query_type .. ".scm")):read()
end

function M.run_all(async_fns, callback)
  a.run(function()
    return a.util.join(async_fns)
  end, callback)
end

return M
