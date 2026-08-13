local async = require "luau-lsp.async"
local config = require "luau-lsp.config"
local fflags = require "luau-lsp.server.fflags"
local log = require "luau-lsp.log"
local types = require "luau-lsp.server.types"
local util = require "luau-lsp.util"

local M = {}

---@param definitions table<string, string>
---@param documentation string[]
---@return string[]
local function build_cmd(definitions, documentation)
  local cmd = { config.get().server.path, "lsp" }

  for name, path in pairs(definitions) do
    if util.is_file(path) then
      table.insert(cmd, "--definitions:" .. name .. "=" .. path)
    else
      log.warn("Definitions file '%s' at '%s' does not exist", name, path)
    end
  end

  for _, path in ipairs(documentation) do
    if util.is_file(path) then
      table.insert(cmd, "--docs=" .. path)
    else
      log.warn("Documentation file at '%s' does not exist", path)
    end
  end

  if not config.get().fflags.enable_by_default then
    table.insert(cmd, "--no-flags-enabled")
  end

  local base_luaurc = config.get().server.base_luaurc
  if base_luaurc then
    base_luaurc = vim.fs.normalize(base_luaurc)
    if util.is_file(base_luaurc) then
      table.insert(cmd, "--base-luaurc=" .. base_luaurc)
    else
      log.warn("Base .luaurc file at '%s' does not exist", base_luaurc)
    end
  end

  return cmd
end

M.refresh_types = async.void(function()
  types.resolve { force = true }
  log.info "Type files have been updated. Run `:lsp restart luau-lsp` to apply changes"
end)

M.setup = async.void(function()
  ---@type vim.lsp.Config
  local lsp_config = {}

  async.join {
    ---@async
    function()
      lsp_config.cmd = build_cmd(types.resolve())
    end,
    ---@async
    function()
      lsp_config.init_options = { fflags = fflags.resolve() }
    end,
  }

  async.await(vim.schedule)

  vim.lsp.config("luau-lsp", lsp_config)
  vim.lsp.enable "luau-lsp"

  require("luau-lsp.roblox").setup()
end)

return M
