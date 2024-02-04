local log = require "luau-lsp.log"

local M = {}
M._callbacks = {}

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
      local compat = require "luau-lsp.compat"
      return vim.fs.dirname(vim.fs.find(function(name)
        return name:match ".*%.project.json$"
          or compat.list_contains({
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
        "Server setting `%s` will not take effect. Check the README.md for more info",
        table.concat(path, ".")
      )
    end
  end

  if vim.tbl_get(opts, "sourcemap", "select_project_file") then
    log.warn "`sourcemap.select_project_file` is deprecated, use `sourcemap.rojo_project` instead"
  end

  -- luau-lsp doesn't really listen to those, they are passed in the command line so they won't
  -- take effect
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
      vim.tbl_get(old_options, vim.split(path, ".")),
      vim.tbl_get(new_options, vim.split(path, "."))
    )
  end

  local function cannot_be_changed(path)
    if has_changed(path) then
      log.warn("`%s` has changed, restart neovim for this to take effect", path)
    end
  end

  -- already configured
  if M.options then
    cannot_be_changed "fflags"
    cannot_be_changed "sourcemap.enabled"
    cannot_be_changed "types"
  end

  M.options = new_options

  for _, data in ipairs(M._callbacks) do
    if has_changed(data.trigger) then
      data.callback()
    end
  end
end

---@param trigger string
---@param callback function
function M.on(trigger, callback)
  table.insert(M._callbacks, {
    path = trigger,
    callback = callback,
  })
end

return M
