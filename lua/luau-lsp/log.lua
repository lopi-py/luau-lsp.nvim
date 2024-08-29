local util = require "luau-lsp.util"

local M = {}

M.level = vim.log.levels.WARN
M.filename = util.joinpath(vim.fn.stdpath "log", "luau-lsp.log")

---@type file*?
local logfile

---@return boolean
local function supports_title()
  return package.loaded["notify"] ~= nil
end

---@param message string
---@param level string
local function write(message, level)
  if not logfile then
    logfile = io.open(M.filename, "a+")
  end
  assert(logfile)
  logfile:write(string.format("%s[%s] %s\n", os.date "%H:%M:%S", level, message))
  logfile:flush()
end

---@param message string
---@param level number
local notify = vim.schedule_wrap(function(message, level)
  if supports_title() then
    vim.notify(message, level, { title = "luau-lsp.nvim" })
  else
    vim.notify(string.format("[%s] %s", "luau-lsp.nvim", message), level)
  end
end)

---@param level string
---@param levelnr number
---@return fun(message: string, ...: any)
local function create_logger(level, levelnr)
  return function(message, ...)
    message = string.format(message, ...)

    write(message, level)

    if levelnr >= M.level then
      notify(message, levelnr)
    end
  end
end

M.debug = create_logger("DEBUG", vim.log.levels.DEBUG)
M.info = create_logger("INFO", vim.log.levels.INFO)
M.warn = create_logger("WARN", vim.log.levels.WARN)
M.error = create_logger("ERROR", vim.log.levels.ERROR)

return M
