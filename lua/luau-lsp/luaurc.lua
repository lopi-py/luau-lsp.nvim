local json = require "luau-lsp.json"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local M = {}

---@param dirs string[]
---@return string?
function M.find_luaurc(dirs)
  if util.is_file ".luaurc" then
    return ".luaurc"
  end

  for _, dir in ipairs(dirs) do
    if util.is_file(vim.fs.joinpath(dir, ".luaurc")) then
      return vim.fs.joinpath(dir, ".luaurc")
    end
  end
end

---@param dirs? string[]
---@return table<string, string>?
function M.aliases(dirs)
  local path = M.find_luaurc(dirs or {})
  if not path then
    return
  end

  local luaurc = io.open(path, "r")
  assert(luaurc)

  local ok, content = pcall(json.decode, luaurc:read "a")
  if not ok then
    log.error("Failed to read '.luaurc': %s", content)
    return
  end

  local aliases = vim.empty_dict()
  for alias, value in pairs(content.aliases or {}) do
    aliases["@" .. alias] = value
  end
  return aliases
end

return M
