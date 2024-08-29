local Path = require "plenary.path"

local M = {}

---@param path string
---@return boolean
function M.is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file" or false
end

---@param key string
---@return string
function M.storage_file(key)
  local storage = Path:new(vim.fn.stdpath "data") / "luau-lsp"
  storage:mkdir { parents = true }

  return tostring(storage / key)
end

---@param callback function
---@param n number
---@return function
function M.on_count(callback, n)
  local counter = 0
  return function()
    counter = counter + 1
    if counter == n then
      callback()
    end
  end
end

---@param fn function
---@return function
function M.once(fn)
  local called = false
  return function(...)
    if not called then
      called = true
      fn(...)
    end
  end
end

---@param bufnr number?
---@return vim.lsp.Client?
function M.get_client(bufnr)
  return vim.lsp.get_clients({ name = "luau-lsp", bufnr = bufnr })[1]
end

return M
