local config = require "luau-lsp.config"

local M = {}

---@param opts { name: string, cmd: string[], version?: string, optional: boolean? }
local function check_executable(opts)
  local ok, job = pcall(vim.system, opts.cmd)
  if not ok then
    local report = opts.optional and vim.health.warn or vim.health.error
    report(string.format("%s: not available", opts.name))
    return
  end

  local result = job:wait()
  local stdout = result.stdout or ""
  if opts.version and vim.version.lt(stdout, opts.version) then
    vim.health.error(
      string.format(
        "%s: required version is `%s`, found `%s`",
        opts.name,
        opts.version,
        vim.trim(stdout)
      )
    )
    return
  end

  vim.health.ok(string.format("%s: `%s`", opts.name, vim.trim(stdout)))
end

local function is_lspconfig_enabled()
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = "lspconfig",
    event = "FileType",
    pattern = "luau",
  })
  return ok and #autocmds > 0
end

local function is_native_lsp_enabled()
  return vim.lsp.is_enabled "luau_lsp"
end

function M.check()
  check_executable {
    name = "luau-lsp",
    cmd = { config.get().server.path, "--version" },
    version = "1.60.0",
  }

  vim.health.start "Setup"

  if is_lspconfig_enabled() then
    vim.health.error "`lspconfig.luau_lsp.setup` was called, this might cause conflicts"
  else
    vim.health.ok "No conflicting setup from `nvim-lspconfig`"
  end

  if is_native_lsp_enabled() then
    vim.health.error '`vim.lsp.enable("luau_lsp")` was called, this might cause conflicts'
  else
    vim.health.ok "No conflicting setup from native lsp"
  end

  vim.health.start "Rojo (required for automatic sourcemap generation)"

  check_executable {
    name = "rojo",
    cmd = { config.get().sourcemap.rojo_path, "--version" },
    version = "7.3.0",
    optional = not (
        config.get().platform.type == "roblox"
        and config.get().sourcemap.enabled
        and config.get().sourcemap.autogenerate
      ),
  }
end

return M
