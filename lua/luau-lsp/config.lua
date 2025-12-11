local log = require "luau-lsp.log"

local PLATFORM_TYPES = {
  "standard",
  "roblox",
}

local ROBLOX_SECURITY_LEVELS = {
  "None",
  "LocalUserSecurity",
  "PluginSecurity",
  "RobloxScriptSecurity",
}

local M = {}

---@alias luau-lsp.PlatformType "standard" | "roblox"
---@alias luau-lsp.RobloxSecurityLevel "None" | "LocalUserSecurity" | "PluginSecurity" | "RobloxScriptSecurity"

---@class luau-lsp.Config : {}
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
    ---@type string[]?
    generator_cmd = nil,
  },
  types = {
    ---@type table<string, string>
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
  server = {
    path = "luau-lsp",
    ---@type string?
    base_luaurc = nil,
  },
}

local options = vim.deepcopy(defaults)

---@param opts luau-lsp.Config
local function validate(opts)
  if opts.server and opts.server.capabilities then
    log.warn "Option 'server.capabilities' is deprecated. See ':help vim.lsp.config'"
    vim.lsp.config("luau-lsp", { capabilities = opts.server.capabilities })
  end

  if opts.server and opts.server.settings then
    log.warn "Option 'server.settings' is deprecated. See ':help vim.lsp.config'"
    vim.lsp.config("luau-lsp", { settings = opts.server.settings })
  end

  if opts.types and opts.types.definition_files and #opts.types.definition_files > 0 then
    log.warn "Option 'types.definition_files' as list is deprecated. Use a table with named keys instead."
  end

  if opts.platform and opts.platform.type then
    if not vim.list_contains(PLATFORM_TYPES, opts.platform.type) then
      log.error("Invalid option 'platform.type' value: " .. opts.platform.type)
    end
  end

  if opts.types and opts.types.roblox_security_level then
    if not vim.list_contains(ROBLOX_SECURITY_LEVELS, opts.types.roblox_security_level) then
      log.error(
        "Invalid option 'types.roblox_security_level' value: " .. opts.types.roblox_security_level
      )
    end
  end
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
