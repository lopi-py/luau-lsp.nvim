local M = {}

---@param str string
---@param opts? table<string, any>
---@return any
function M.decode(str, opts)
  str = str
    :gsub("//[^\n]*", "")
    :gsub("/%*.-%*/", "")
    :gsub(",%s*([}%]])", "%1")
    :gsub("([%{%s,])([%a_][%w_]*)%s*:", '%1"%2":')

  return vim.json.decode(str, opts or {})
end

return M
