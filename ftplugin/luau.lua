if not vim.g.loaded_luau_lsp then
  require("luau-lsp.roblox").setup()
end

vim.g.loaded_luau_lsp = true

require("luau-lsp.server").start()
