local M = {}

function M.treesitter()
  local log = require "luau-lsp.log"
  log.warn "A custom luau treesitter parser is no longer required"
end

---@param opts LuauLspConfig
function M.config(opts)
  require("luau-lsp.config").config(opts)
end

---@param opts? LuauLspConfig
function M.setup(opts)
  require("luau-lsp.config").config(opts or {})
  require("luau-lsp.command").setup()
  require("luau-lsp.server").setup()
  require("luau-lsp.sourcemap").setup()

  if vim.version().minor < 10 then
    vim.filetype.add {
      extension = {
        luau = "luau",
      },
      filename = {
        [".luaurc"] = "jsonc",
      },
    }
  end
end

return M
