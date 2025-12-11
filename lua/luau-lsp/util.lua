local curl = require "plenary.curl"

local M = {}

M.is_windows = vim.uv.os_uname().sysname == "Windows_NT"

---@param path string
---@return boolean
function M.is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file" or false
end

---@param path string
---@return boolean
function M.is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "directory" or false
end

---@vararg string
---@return string
function M.joinpath(...)
  return table.concat({ ... }, M.is_windows and "\\" or "/")
end

---@vararg string
---@return string
function M.storage_file(...)
  local args = { ... }
  local path = M.joinpath(vim.fn.stdpath "data", "luau-lsp", unpack(args, 1, #args - 1))
  if not M.is_dir(path) then
    vim.fn.mkdir(path, "p")
  end
  return M.joinpath(path, args[#args])
end

---@param bufnr? integer
---@return vim.lsp.Client?
function M.get_client(bufnr)
  return vim.lsp.get_clients({ name = "luau-lsp", bufnr = bufnr })[1]
end

---@param url string
---@param output string
---@param callback fun(err?: string, path?: string)
function M.download_file(url, output, callback)
  curl.get(url, {
    output = output,
    callback = vim.schedule_wrap(function()
      callback(nil, output)
    end),
    on_error = vim.schedule_wrap(function(result)
      callback(result.stderr)
    end),
  })
end

return M
