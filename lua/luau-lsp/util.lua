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

---@param key string
---@return string
function M.storage_file(key)
  local path = M.joinpath(vim.fn.stdpath "data", "luau-lsp")
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

---@param bufnr? integer
---@return vim.lsp.Client?
function M.get_client(bufnr)
  return vim.lsp.get_clients({ name = "luau-lsp", bufnr = bufnr })[1]
end

---@param tbl table
---@param max_depth number
---@param current_depth? number
---@return table
function M.limit_table_depth(tbl, max_depth, current_depth)
  current_depth = current_depth or 0
  if current_depth >= max_depth then
    return {}
  end

  local result = {}
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      result[key] = M.limit_table_depth(value, max_depth, current_depth + 1)
    else
      result[key] = value
    end
  end
  return result
end

return M
