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
      local util = require "luau-lsp.util"
      return vim.fs.dirname(vim.fs.find(function(name)
        return name:match ".*%.project.json$"
          or util.list_contains({
            ".git",
            ".luaurc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
          }, name)
      end, {
        upward = true,
        path = path,
      })[1])
    end,
    -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
    settings = {},
  },
}

---@param opts LuauLspConfig
local function validate_config(opts)
  local function verify_server_client_setting(path)
    if vim.tbl_get(opts, "server", "settings", "luau-lsp", unpack(path)) ~= nil then
      log.warn(
        "Server setting `%s' will not take effect. Check the README.md for more info",
        table.concat(path, ".")
      )
    end
  end

  if vim.tbl_get(opts, "sourcemap", "select_project_file") then
    log.warn "`sourcemap.select_project_file` is deprecated, use `sourcemap.rojo_project` instead"
  end

  -- luau-lsp doesn't really listen to those, they are passed in the command line so restart is
  -- needed
  verify_server_client_setting { "fflags" }
  verify_server_client_setting { "sourcemap" }
  verify_server_client_setting { "types" }
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

  local old_options = M.options or defaults
  local new_options = vim.tbl_deep_extend("force", old_options, options)

  local function has_changed(path)
    return not vim.deep_equal(
      vim.tbl_get(old_options, unpack(path)) or {},
      vim.tbl_get(new_options, unpack(path)) or {}
    )
  end

  local function verify_if_restart_needed(path)
    if has_changed(path) then
      log.warn("`%s` has changed, restart neovim for this to take effect", table.concat(path, "."))
    end
  end

  -- setup has already been called so we're trying to override previous options
  if M.options then
    verify_if_restart_needed { "fflags" }
    verify_if_restart_needed { "sourcemap", "enabled" }
    verify_if_restart_needed { "types" }
  end

  M.options = new_options

  -- sourcemap.rojo_project_file has changed so update the generation if needed
  local sourcemap = require "luau-lsp.sourcemap"
  if
    has_changed { "sourcemap", "rojo_project_file" }
    and M.options.sourcemap.autogenerate
    and sourcemap.is_running()
  then
    sourcemap.stop()
    sourcemap.start()
  end
end

---@param options? LuauLspConfig
function M.setup(options)
  validate_config(options or {})

  if M.options then
    -- .config was called first, so give them more priority
    M.options = vim.tbl_deep_extend("force", options or {}, M.options)
  else
    -- fresh options setup
    M.options = vim.tbl_deep_extend("force", defaults, options or {})
  end

  require("luau-lsp.sourcemap").setup()
  require("luau-lsp.server").setup()
end

return M
