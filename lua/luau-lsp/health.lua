local config = require "luau-lsp.config"

local M = {}

---@param opts { name: string, cmd: string[], version?: string }
local function check_executable(opts)
  if not opts.cmd[1] or vim.fn.executable(opts.cmd[1]) ~= 1 then
    vim.health.error(string.format("%s: not available", opts.name))
    return
  end

  if not opts.version then
    vim.health.ok(string.format("%s: `%s`", opts.name, opts.cmd[1]))
    return
  end

  local ok, job = pcall(vim.system, opts.cmd)
  if not ok then
    vim.health.error(string.format("%s: failed to run `%s`", opts.name, opts.cmd[1]))
    return
  end

  local result = job:wait()
  if result.code ~= 0 then
    vim.health.error(string.format("%s: failed to run `%s`", opts.name, opts.cmd[1]))
    return
  end

  local version = vim.trim(result.stdout --[[@as string]])
  if vim.version.lt(version, opts.version) then
    vim.health.error(
      string.format("%s: required version is `%s`, found `%s`", opts.name, opts.version, version)
    )
    return
  end

  vim.health.ok(string.format("%s: `%s`", opts.name, version))
end

local function check_sourcemap_generator()
  if config.get().platform.type ~= "roblox" then
    return
  end
  if not config.get().sourcemap.enabled or not config.get().sourcemap.autogenerate then
    return
  end

  vim.health.start "Sourcemap generator"

  local generator_cmd = config.get().sourcemap.generator_cmd
  if generator_cmd then
    check_executable {
      name = "custom generator",
      cmd = generator_cmd,
    }
    return
  end

  check_executable {
    name = "rojo",
    cmd = { config.get().sourcemap.rojo_path, "--version" },
    version = "7.3.0",
  }
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

  check_sourcemap_generator()
end

return M
