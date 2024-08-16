local Job = require "plenary.job"
local config = require "luau-lsp.config"

local M = {}

---@param opts { name: string, cmd: string[], version?: string, required: boolean? }
local function check_executable(opts)
  local ok, job = pcall(Job.new, Job, {
    command = opts.cmd[1],
    args = vim.list_slice(opts.cmd, 2),
  })

  if not ok then
    local report = opts.required == false and vim.health.warn or vim.health.error
    report(string.format("%s: not available", opts.name))
    return
  end

  if opts.version then
    local version = table.concat(job:sync(), "\n")
    if vim.version.ge(version, opts.version) then
      vim.health.ok(string.format("%s: `%s`", opts.name, tostring(version)))
    else
      vim.health.error(
        string.format(
          "%s: required version is `%s`, found `%s`",
          opts.name,
          opts.version:gsub("a", "b"),
          version
        )
      )
    end
  end
end

function M.check()
  vim.health.start "luau-lsp"

  check_executable {
    name = "luau-lsp",
    cmd = { config.get().server.cmd[1], "--version" },
    version = "1.32.0",
  }

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

  vim.health.start "Rojo (required for automatic sourcemap generation)"

  check_executable {
    name = "rojo",
    cmd = { config.get().sourcemap.rojo_path, "--version" },
    version = "7.3.0",
    required = config.get().platform.type == "roblox"
      and config.get().sourcemap.enabled
      and config.get().sourcemap.autogenerate,
  }
end

return M
