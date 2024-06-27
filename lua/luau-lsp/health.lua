local M = {}

function M.check()
  vim.health.start "luau-lsp.nvim"

  if vim.fn.executable "luau-lsp" == 1 then
    local version = require("luau-lsp.server").version()

    if vim.version.ge(version, "1.30.0") then
      vim.health.ok("`luau-lsp` version is " .. tostring(version))
    else
      vim.health.error("Required `luau-lsp` version is 1.30.0, found " .. tostring(version))
    end
  else
    vim.health.error "`luau-lsp` is not an executable"
  end

  if vim.version().minor >= 10 then
    vim.health.ok("Neovim version is " .. tostring(vim.version()))
  else
    vim.health.warn "Not running Neovim 0.10+, luau-lsp will display an error `server not yet received configuration for diagnostics`"
  end
end

return M
