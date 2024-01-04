local Path = require "plenary.path"
local util = require "luau-lsp.util"

local PLUGIN_NAME = "luau-lsp.nvim"

local levels = vim.deepcopy(vim.log.levels)
vim.tbl_add_reverse_lookup(levels)

local function create_logger(level)
  return function(message, ...)
    local file = Path:new(util.storage_file "luau-lsp.log")
    local timestr = vim.fn.strftime "%H:%M:%S"
    message = string.format(message, ...)

    file:write(string.format("%s[%s]: %s\n", timestr, levels[level], message), "a")

    if level >= levels.WARN then
      vim.notify(message, level, { title = PLUGIN_NAME })
    end
  end
end

local M = {}

M.info = create_logger(levels.INFO)
M.warn = create_logger(levels.WARN)
M.error = create_logger(levels.ERROR)

return M
