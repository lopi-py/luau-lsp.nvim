local M = {}

function M.check()
  vim.health.start "luau-lsp.nvim"

  if vim.fn.executable "luau-lsp" == 1 then
    local version = vim.version.parse(vim.fn.system { "luau-lsp", "--version" })
    if not version then
      vim.health.error "Could not parse luau-lsp version"
      return
    end

    if vim.version.ge(version, "1.27.0") then
      vim.health.ok("luau-lsp version is " .. tostring(version))
    else
      vim.health.warn("Recommended luau-lsp version is 1.27.0, found " .. tostring(version))
    end
  else
    vim.health.error "luau-lsp is not an executable"
  end

  if vim.version().minor >= 10 then
    vim.health.ok "Running on Neovim 0.10+"
  else
    vim.health.warn "Not running Neovim 0.10+, luau-lsp will display an error `server not yet received configuration for diagnostics`"
  end
end

return M
