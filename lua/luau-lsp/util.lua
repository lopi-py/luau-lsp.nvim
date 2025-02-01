local M = {}

M.is_windows = vim.uv.os_uname().sysname == "Windows_NT"

---@param path string
---@return boolean
function M.is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file" or false
end

function M.is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "directory" or false
end

---@vararg string
---@return string
function M.joinpath(...)
  return table.concat({ ... }, M.is_windows and "\\" or "/")
end

---@param key string
---@return string
function M.storage_file(key)
  local path = M.joinpath(vim.fn.stdpath "data" --[[@as string]], "luau-lsp")
  if not M.is_dir(path) then
    vim.fn.mkdir(path, "p")
  end
  return M.joinpath(path, key)
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

---@param bufnr integer?
---@return vim.lsp.Client?
function M.get_client(bufnr)
  return vim.lsp.get_clients({ name = "luau-lsp", bufnr = bufnr })[1]
end

return M
