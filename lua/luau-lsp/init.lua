local M = {}

---@param opts luau-lsp.Config.Partial
function M.config(opts)
  require("luau-lsp.config").config(opts)
end

---@param opts luau-lsp.Config.Partial
function M.setup(opts)
  require("luau-lsp.config").config(opts)
end

return M
