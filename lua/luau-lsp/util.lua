local M = {}

---@param path string
---@return boolean
function M.is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file" or false
end

---@param ... string
---@return string
function M.data_file(...)
  local path = vim.fs.joinpath((vim.fn.stdpath "data") --[[@as string]], "luau-lsp", ...)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  return path
end

---@param bufnr? integer
---@return vim.lsp.Client?
function M.get_client(bufnr)
  return vim.lsp.get_clients({ name = "luau-lsp", bufnr = bufnr })[1]
end

---@generic T : table
---@param tbl T
---@param max_depth number
---@return T
function M.truncate_table_depth(tbl, max_depth)
  local function truncate(value, depth)
    if depth >= max_depth then
      return {}
    end

    local result = {}
    for key, child in pairs(value) do
      result[key] = type(child) == "table" and truncate(child, depth + 1) or child
    end
    return result
  end

  return truncate(tbl, 0)
end

return M
