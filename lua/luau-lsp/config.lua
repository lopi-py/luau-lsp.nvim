local log = require "luau-lsp.log"

local callbacks = {}

local M = {}

---@type LuauLspConfig
M.options = nil

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
  plugin = {
    enabled = false,
    port = 3667,
  },
  ---@type table<string, any>
  server = {
    cmd = { "luau-lsp", "lsp" },
    root_dir = function(path)
      local server = require "luau-lsp.server"
      return server.find_root(path, function(name)
        return name:match ".*%.project.json$"
      end) or server.find_root(path, {
        ".git",
        ".luaurc",
        "stylua.toml",
        "selene.toml",
        "selene.yml",
      })
    end,
    single_file_support = true,
    -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
    settings = {},
  },
}

---@param options LuauLspConfig
local function validate_config(options)
  local function check_server_setting(path)
    if vim.tbl_get(options, "server", "settings", "luau-lsp", path) ~= nil then
      log.warn("Server setting `%s` will not take effect. Check the README.md for more info", path)
    end
  end

  if vim.tbl_get(options, "sourcemap", "select_project_file") then
    log.warn "`sourcemap.select_project_file` is deprecated, use `sourcemap.rojo_project` instead"
  end

  -- luau-lsp doesn't really listen to those, they are passed in the command line so they won't
  -- take effect
  check_server_setting "fflags"
  check_server_setting "sourcemap"
  check_server_setting "types"
  check_server_setting "plugin"
end

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
