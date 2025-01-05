local log = require "luau-lsp.log"

local PLATFORMS = { "standard", "roblox" }
local SECURITY_LEVELS = { "None", "LocalUserSecurity", "PluginSecurity", "RobloxScriptSecurity" }

local M = {}

---@alias luau-lsp.PlatformType "standard" | "roblox"
---@alias luau-lsp.RobloxSecurityLevel "None" | "LocalUserSecurity" | "PluginSecurity" | "RobloxScriptSecurity"

---@class luau-lsp.Config
local defaults = {
  platform = {
    ---@type luau-lsp.PlatformType
    type = "roblox",
  },
  sourcemap = {
    enabled = true,
    autogenerate = true,
    rojo_path = "rojo",
    rojo_project_file = "default.project.json",
    include_non_scripts = true,
    sourcemap_file = "sourcemap.json",
  },
  types = {
    ---@type string[]
    definition_files = {},
    ---@type string[]
    documentation_files = {},
    ---@type luau-lsp.RobloxSecurityLevel
    roblox_security_level = "PluginSecurity",
  },
  fflags = {
    enable_by_default = false,
    enable_new_solver = false,
    sync = true,
    ---@type table<string, string>
    override = {},
  },
  plugin = {
    enabled = false,
    port = 3667,
  },
  ---@class luau-lsp.ClientConfig: vim.lsp.ClientConfig
  server = {
    ---@type string[]
    cmd = { "luau-lsp", "lsp" },
    ---@type fun(path: string): string?
    root_dir = function(path)
      return vim.fs.root(path, function(name)
        return name:match ".+%.project%.json$"
      end) or vim.fs.root(path, {
        ".git",
        ".luaurc",
        "selene.toml",
        "stylua.toml",
      })
    end,
  },
}

local options = defaults

---@param opts luau-lsp.Config
local function validate(opts)
  if vim.tbl_get(opts, "platform", "type") then
    if not vim.list_contains(PLATFORMS, opts.platform.type) then
      log.error("Invalid option 'platform.type' value: " .. opts.platform.type)
    end
  end

  if vim.tbl_get(opts, "types", "roblox_security_level") then
    if not vim.list_contains(SECURITY_LEVELS, opts.types.roblox_security_level) then
      log.error(
        "Invalid option 'types.roblox_security_level' value: " .. opts.types.roblox_security_level
      )
    end
  end

  local function check_server_setting(name)
    if vim.tbl_get(opts, "server", "settings", "luau-lsp", name) ~= nil then
      log.error("'%s' should not be passed as server setting", name)
    end
  end

  check_server_setting "platform"
  check_server_setting "sourcemap"
  check_server_setting "types"
  check_server_setting "fflags"
  check_server_setting "plugin"
end

---@return luau-lsp.Config
function M.get()
  return options
end

---@param opts luau-lsp.Config
function M.config(opts)
  validate(opts)
  options = vim.tbl_deep_extend("force", options, opts)
end

return M
