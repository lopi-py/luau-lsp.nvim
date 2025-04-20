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

function M.check()
  vim.health.start "luau-lsp"

  check_executable {
    name = "luau-lsp",
    cmd = { config.get().server.path, "--version" },
    version = "1.38.0",
  }

  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = "lspconfig",
    event = "FileType",
    pattern = "luau",
  })
  if ok and #autocmds > 0 then
    vim.health.error "`lspconfig.luau_lsp.setup` was called, it may cause conflicts"
  else
    vim.health.ok "No conflicts with `nvim-lspconfig`"
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
