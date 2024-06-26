local compat = require "luau-lsp.compat"
local log = require "luau-lsp.log"

local PLATFORMS = { "standard", "roblox" }
local SECURITY_LEVELS = { "None", "LocalUserSecurity", "PluginSecurity", "RobloxScriptSecurity" }

local callbacks = {}

local M = {}

---@type luau-lsp.Config
M.options = nil

---@class luau-lsp.Config
local defaults = {
  platform = {
    ---@type "standard"|"roblox"
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
    ---@type "None"|"LocalUserSecurity"|"PluginSecurity"|"RobloxScriptSecurity"
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
  ---@type table<string, any>
  server = {
    cmd = { "luau-lsp", "lsp" },
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
    -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
    settings = {},
  },
}

---@param options luau-lsp.Config
local function validate_config(options)
  if vim.tbl_get(options, "platform", "type") then
    if not compat.list_contains(PLATFORMS, options.platform.type) then
      log.error("Invalid option `platform.type` value: " .. options.platform.type)
    end
  end

  if vim.tbl_get(options, "types", "roblox_security_level") then
    if not compat.list_contains(SECURITY_LEVELS, options.types.roblox_security_level) then
      log.error(
        "Invalid option `types.roblox_security_level` value: "
          .. options.types.roblox_security_level
      )
    end
  end

  if vim.tbl_get(options, "sourcemap", "select_project_file") ~= nil then
    log.warn "`sourcemap.select_project_file` is deprecated, use `sourcemap.rojo_project` instead"
  end

  if vim.tbl_get(options, "types", "roblox") ~= nil then
    log.warn "`types.roblox` is deprecated, use `platform.type` instead"
  end

  local function check_server_setting(path)
    if vim.tbl_get(options, "server", "settings", "luau-lsp", path) ~= nil then
      log.warn("Server setting `%s` will not take effect. Check the README.md for more info", path)
    end
  end

  -- luau-lsp doesn't really listen to those, they are passed in the command line or are used to
  -- start the server so they won't take effect
  check_server_setting "platform"
  check_server_setting "sourcemap"
  check_server_setting "types"
  check_server_setting "fflags"
  check_server_setting "plugin"
end

---@return luau-lsp.Config
function M.get()
  return M.options
end

---@param options luau-lsp.Config
function M.config(options)
  validate_config(options)

  local old_options = M.options or defaults
  local new_options = vim.tbl_deep_extend("force", old_options, options)

  local function has_changed(path)
    return not vim.deep_equal(
      vim.tbl_get(old_options, unpack(vim.split(path, "%."))),
      vim.tbl_get(new_options, unpack(vim.split(path, "%.")))
    )
  end

  M.options = new_options

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
