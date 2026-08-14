local log = require "luau-lsp.log"

---@class luau-lsp.Config.Platform
---@field type "standard" | "roblox"

---@class luau-lsp.Config.Sourcemap
---@field enabled boolean
---@field autogenerate boolean
---@field rojo_path string
---@field rojo_project_file string
---@field include_non_scripts boolean
---@field sourcemap_file string
---@field generator_cmd? string[]

---@class luau-lsp.Config.Types
---@field definition_files table<string, string>
---@field documentation_files string[]
---@field roblox_security_level "None" | "LocalUserSecurity" | "PluginSecurity" | "RobloxScriptSecurity"

---@class luau-lsp.Config.Fflags
---@field enable_by_default boolean
---@field enable_new_solver boolean
---@field sync boolean
---@field override table<string, string | number | boolean>

---@class luau-lsp.Config.Plugin
---@field enabled boolean
---@field port integer

---@class luau-lsp.Config.Server
---@field path string
---@field base_luaurc? string

---@class luau-lsp.Config
---@field platform luau-lsp.Config.Platform
---@field sourcemap luau-lsp.Config.Sourcemap
---@field types luau-lsp.Config.Types
---@field fflags luau-lsp.Config.Fflags
---@field plugin luau-lsp.Config.Plugin
---@field server luau-lsp.Config.Server

---@class luau-lsp.Config.Partial
---@field platform? Partial<luau-lsp.Config.Platform>
---@field sourcemap? Partial<luau-lsp.Config.Sourcemap>
---@field types? Partial<luau-lsp.Config.Types>
---@field fflags? Partial<luau-lsp.Config.Fflags>
---@field plugin? Partial<luau-lsp.Config.Plugin>
---@field server? Partial<luau-lsp.Config.Server>

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

---@type luau-lsp.Config
local defaults = {
  platform = {
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
    definition_files = {},
    documentation_files = {},
    roblox_security_level = "PluginSecurity",
  },
  fflags = {
    enable_by_default = false,
    enable_new_solver = false,
    sync = true,
    override = {},
  },
  plugin = {
    enabled = false,
    port = 3667,
  },
  server = {
    path = "luau-lsp",
  },
}

local options = vim.deepcopy(defaults)

---@param opts luau-lsp.Config.Partial
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

---@param opts luau-lsp.Config.Partial
function M.config(opts)
  validate(opts)
  options = vim.tbl_deep_extend("force", options, opts) --[[@as luau-lsp.Config]]
end

---@private
function M._reset()
  options = vim.deepcopy(defaults)
end

return M
