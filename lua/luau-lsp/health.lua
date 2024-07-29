local server = require "luau-lsp.server"

local M = {}

function M.check()
  vim.health.start "luau-lsp.nvim"

  if vim.fn.executable "luau-lsp" == 0 then
    vim.health.error "`luau-lsp` is not an executable"
    return
  end

  local version = server.version()
  if vim.version.ge(version, "1.32.0") then
    vim.health.ok("`luau-lsp` version is " .. tostring(version))
  else
    vim.health.error("Required `luau-lsp` version is 1.32.0, found " .. tostring(version))
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
end

return M
