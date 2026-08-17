local config = require "luau-lsp.config"
local log = require "luau-lsp.log"

---@class luau-lsp.Command
---@field execute fun()
---@field enabled? fun(): boolean

local M = {}

---@type table<string, luau-lsp.Command?>
local commands = {
  log = {
    execute = function()
      vim.cmd.tabnew(log.filename)
    end,
  },
  bytecode = {
    execute = require("luau-lsp.compiler").show_bytecode,
  },
  compiler_remarks = {
    execute = require("luau-lsp.compiler").show_remarks,
  },
  codegen = {
    execute = require("luau-lsp.compiler").show_codegen,
  },
  internal_source = {
    execute = require("luau-lsp.internal_source").show,
  },
  regenerate_sourcemap = {
    execute = require("luau-lsp.roblox.sourcemap").start,
    enabled = function()
      return config.get().platform.type == "roblox" and config.get().sourcemap.enabled
    end,
  },
  refresh_types = {
    execute = require("luau-lsp.server").refresh_types,
  },
}

---@param command luau-lsp.Command
---@return boolean
local function is_enabled(command)
  return command.enabled == nil or command.enabled()
end

---@param arglead string
---@return string[]
function M.complete(arglead)
  local items = vim.tbl_keys(commands)
  table.sort(items)

  return vim.tbl_filter(function(item)
    local command = commands[item]
    return command ~= nil and vim.startswith(item, arglead) and is_enabled(command)
  end, items)
end

---@param args string[]
function M.execute(args)
  local command = commands[args[1]]
  if not command then
    log.error("Invalid command '%s'", args[1])
  elseif not is_enabled(command) then
    log.error("Command '%s' is disabled", args[1])
  else
    command.execute()
  end
end

return M
