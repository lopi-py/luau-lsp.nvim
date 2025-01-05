local M = {}

function M.aliases()
  require("luau-lsp.log").warn 'require("luau-lsp").aliases() is deprecated, not needed anymore'
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
