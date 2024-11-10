local M = {}

---@return table<string, string>?
function M.aliases()
  return require("luau-lsp.luaurc").aliases { "lib", "src" }
end

---@param opts luau-lsp.Config
function M.config(opts)
  require("luau-lsp.config").config(opts)
end

---@param opts luau-lsp.Config
function M.setup(opts)
  require("luau-lsp.config").config(opts)
end

return M
