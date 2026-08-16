local log = require "luau-lsp.log"

---@class luau-lsp.Command
---@field execute fun()

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
  regenerate_sourcemap = {
    execute = require("luau-lsp.roblox.sourcemap").start,
  },
  refresh_types = {
    execute = require("luau-lsp.server").refresh_types,
  },
}

---@param arglead string
---@return string[]
function M.complete(arglead)
  local items = vim.tbl_keys(commands)
  table.sort(items)

  return vim.tbl_filter(function(item)
    return vim.startswith(item, arglead)
  end, items)
end

---@param args string[]
function M.execute(args)
  if commands[args[1]] then
    commands[args[1]].execute()
  else
    log.error("Invalid command '%s'", args[1])
  end
end

return M
