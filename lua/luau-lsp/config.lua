local compat = require "luau-lsp.compat"
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
      local server = require "luau-lsp.server"
      return server.root(path, function(name)
        return name:match ".*%.project.json$"
      end) or server.root(path, {
        ".git",
        ".luaurc",
        "stylua.toml",
        "selene.toml",
        "selene.yml",
      })
    end,
  },
}

local options = defaults
local callbacks = {}

---@param opts luau-lsp.Config
local function validate(opts)
  if vim.tbl_get(opts, "platform", "type") then
    if not compat.list_contains(PLATFORMS, opts.platform.type) then
      log.error("Invalid option `platform.type` value: " .. opts.platform.type)
    end
  end

  if vim.tbl_get(opts, "types", "roblox_security_level") then
    if not compat.list_contains(SECURITY_LEVELS, opts.types.roblox_security_level) then
      log.error(
        "Invalid option `types.roblox_security_level` value: " .. opts.types.roblox_security_level
      )
    end
  end

  if vim.tbl_get(opts, "types", "roblox") ~= nil then
    log.warn "`types.roblox` is deprecated, use `platform.type` instead"
  end

  local function check_server_setting(path)
    if vim.tbl_get(opts, "server", "settings", "luau-lsp", path) ~= nil then
      log.error("`%s` should not be pased as server setting", path)
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

  local old_options = options
  local new_options = vim.tbl_deep_extend("force", old_options, opts)

  local function has_changed(path)
    return not vim.deep_equal(
      vim.tbl_get(old_options, unpack(vim.split(path, "%."))),
      vim.tbl_get(new_options, unpack(vim.split(path, "%.")))
    )
  end

  options = new_options

  for callback, path in pairs(callbacks) do
    if has_changed(path) then
      callback()
    end
  end
end

---@param path string
---@param callback function
function M.on(path, callback)
  callbacks[callback] = path
end

return M
