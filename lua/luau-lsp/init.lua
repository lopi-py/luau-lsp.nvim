local M = {}

function M.treesitter()
  local log = require "luau-lsp.log"
  log.warn "A custom luau treesitter parser is no longer required"
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
