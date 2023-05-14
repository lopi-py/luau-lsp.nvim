local M = {}

---@param config LuauLspConfig
function M.setup(config)
  require("luau-lsp.config").setup(config)
  require("luau-lsp.sourcemap").setup()
  require("luau-lsp.server").setup()
  M._setup_commands()
end

function M._setup_commands()
  vim.api.nvim_create_user_command("RojoSourcemap", function()
    require("luau-lsp.sourcemap").generate()
  end, {})
end

return M
