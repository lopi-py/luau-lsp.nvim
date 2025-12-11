local log = require "luau-lsp.log"

---@class luau-lsp.Command
---@field execute fun(args: string[])
---@field complete? string[] | fun(): string[]

local M = {}

---@type table<string, luau-lsp.Command>
local commands = {
  log = {
    execute = function()
      vim.cmd.tabnew(log.filename)
    end,
  },
  bytecode = {
    execute = require("luau-lsp.bytecode").bytecode,
  },
  compiler_remarks = {
    execute = require("luau-lsp.bytecode").compiler_remarks,
  },
  regenerate_sourcemap = {
    execute = require("luau-lsp.roblox.sourcemap").start,
  },
  redownload_api = {
    execute = require("luau-lsp.server").download_api,
  },
}

---@param cmdline string
---@return string
---@return string[]
local function parse(cmdline)
  local args = vim.split(vim.trim(cmdline), "%s+")
  if args[1] == "LuauLsp" then
    table.remove(args, 1)
  end

  local command = table.remove(args, 1)
  return command, args
end

---@param arglead string
---@param cmdline string
---@return string[]
function M.complete(arglead, cmdline)
  local command, args = parse(cmdline)
  local items = {}

  if commands[command] then
    local complete = commands[command].complete
    if type(complete) == "function" then
      vim.list_extend(items, complete())
    elseif type(complete) == "table" then
      vim.list_extend(items, complete)
    end

    if vim.list_contains(items, args[1]) then
      items = {}
    end
  else
    vim.list_extend(items, vim.tbl_keys(commands))
  end

  table.sort(items)

  return vim.tbl_filter(function(item)
    return vim.startswith(item, arglead)
  end, items)
end

---@param cmdline string
function M.execute(cmdline)
  local command, args = parse(cmdline)
  if commands[command] then
    commands[command].execute(args)
  else
    log.error("Invalid command '%s'", command)
  end
end

return M
