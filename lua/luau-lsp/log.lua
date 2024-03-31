local Path = require "plenary.path"
local util = require "luau-lsp.util"

local PLUGIN_NAME = "luau-lsp.nvim"
local LOG_FILE = Path:new(util.storage_file "luau-lsp.log")

local levels_lookup = {}
for k, v in pairs(vim.log.levels) do
  levels_lookup[v] = k
end

local function supports_title()
  local success = pcall(require, "notify")
  return success
end

local function create_logger(level)
  return vim.schedule_wrap(function(message, ...)
    local timestr = vim.fn.strftime "%H:%M:%S"
    message = string.format(message, ...)

    LOG_FILE:write(string.format("%s[%s]: %s\n", timestr, levels_lookup[level], message), "a")

    if level >= vim.log.levels.WARN then
      if not supports_title() then
        message = string.format("[%s]: %s", PLUGIN_NAME, message)
      end

      vim.notify(message, level, { title = PLUGIN_NAME })
    end
  end)
end

local M = {}

M.log_file = tostring(LOG_FILE)
M.debug = create_logger(vim.log.levels.DEBUG)
M.info = create_logger(vim.log.levels.INFO)
M.warn = create_logger(vim.log.levels.WARN)
M.error = create_logger(vim.log.levels.ERROR)

return M
