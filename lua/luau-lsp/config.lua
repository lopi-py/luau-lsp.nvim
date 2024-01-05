local log = require "luau-lsp.log"

local M = {}

---@class LuauLspConfig
local defaults = {
  sourcemap = {
    enabled = true,
    autogenerate = true,
    rojo_path = "rojo",
    rojo_project_file = "default.project.json",
    include_non_scripts = true,
  },
  types = {
    ---@type string[]
    definition_files = {},
    ---@type string[]
    documentation_files = {},
    roblox = true,
    roblox_security_level = "PluginSecurity",
  },
  fflags = {
    enable_by_default = false,
    sync = true,
    ---@type table<string, "True"|"False"|number>
    override = {},
  },
  ---@type table<string, any>
  server = {
    cmd = { "luau-lsp", "lsp" },
    root_dir = function(path)
      local util = require "lspconfig.util"
      return util.find_git_ancestor(path)
        or util.root_pattern(
          ".luaurc",
          "selene.toml",
          "stylua.toml",
          "aftman.toml",
          "wally.toml",
          "mantle.yml",
          "*.project.json"
        )(path)
    end,
    -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
    settings = {},
  },
}

---@param opts LuauLspConfig
local function validate_config(opts)
  local function verify_server_client_setting(path)
    path = type(path) == "table" and path or { path }
    if vim.tbl_get(opts, "server", "settings", "luau-lsp", unpack(path)) then
      log.warn(
        "Server setting '%s' will not take effect. Check the README.md for more info",
        table.concat(path, ".")
      )
    end
  end

  if vim.tbl_get(opts, "sourcemap", "select_project_file") then
    log.warn "`sourcemap.select_project_file` is deprecated, use `sourcemap.rojo_project` instead"
  end

  -- luau-lsp doesn't really listen to those, they are passed in the command line so restart is
  -- needed
  verify_server_client_setting "fflags"
  verify_server_client_setting "sourcemap"
  verify_server_client_setting "types"
end

---@type LuauLspConfig
M.options = nil

---@return LuauLspConfig
function M.get()
  return M.options
end

---@param options LuauLspConfig
function M.config(options)
  validate_config(options)

  options = vim.tbl_deep_extend("force", M.options or defaults, options)

  local function verify_if_restart_needed(path)
    path = type(path) == "table" and path or { path }
    if
      not vim.deep_equal(
        vim.tbl_get(M.options, unpack(path)) or {},
        vim.tbl_get(options, unpack(path)) or {}
      )
    then
      log.warn(
        "`%s` has changed, restart the server for this to take effect",
        table.concat(path, ".")
      )
    end
  end

  -- setup has already been called so we're trying to override previous options
  if M.options then
    verify_if_restart_needed "fflags"
    verify_if_restart_needed { "sourcemap", "enabled" }
    verify_if_restart_needed "types"
  end

  M.options = options

  -- sourcemap.rojo_project_file has changed so update the generation if needed
  local sourcemap = require "luau-lsp.sourcemap"
  if vim.tbl_get(options, "sourcemap", "rojo_project_file") and sourcemap.is_running() then
    sourcemap.stop()
    sourcemap.watch()
  end
end

---@param options? LuauLspConfig
function M.setup(options)
  validate_config(options or {})

  if M.options then
    -- .config was called first, so prefer give them more priority
    M.options = vim.tbl_deep_extend("force", options or {}, M.options)
  else
    -- fresh options setup
    M.options = vim.tbl_deep_extend("force", defaults, options or {})
  end

  require("luau-lsp.sourcemap").setup()
  require("luau-lsp.server").setup()
end

return M
