local M = {}

function M.check()
  vim.health.start "luau-lsp"

  if vim.fn.executable "luau-lsp" == 1 then
    local version = require("luau-lsp.server").version()
    if vim.version.ge(version, "1.32.0") then
      vim.health.ok(string.format("luau-lsp: `%s`", tostring(version)))
    else
      vim.health.error(
        string.format("luau-lsp: required version is `1.32.0`, found `%s`", tostring(version))
      )
    end
  else
    vim.health.error "luau-lsp: not available"
  end

  local autocmds = vim.api.nvim_get_autocmds {
    group = "lspconfig",
    event = "FileType",
    pattern = "luau",
  }

  if #autocmds == 0 then
    vim.health.ok "No conflicts with `nvim-lspconfig`"
  else
    vim.health.error "`lspconfig.luau_lsp.setup` was called, it may cause conflicts"
  end

  vim.health.start "Rojo (required for sourcemap generation)"

  if vim.fn.executable "rojo" == 1 then
    local version = require("luau-lsp.roblox.sourcemap").version()
    if vim.version.ge(version, "7.3.0") then
      vim.health.ok(string.format("rojo: `%s`", tostring(version)))
    else
      vim.health.error(
        string.format("rojo: required version is `7.3.0`, found `%s`", tostring(version))
      )
    end
  else
    vim.health.warn "rojo: not available"
  end
end

return M
