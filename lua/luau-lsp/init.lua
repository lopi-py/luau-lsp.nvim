local json = require "luau-lsp.json"
local log = require "luau-lsp.log"

---@param paths string[]
---@return file*?
local function find_luaurc(paths)
  local luaurc = io.open(".luaurc", "r")
  if luaurc then
    return luaurc
  end

  for _, path in ipairs(paths) do
    luaurc = io.open(path .. "/.luaurc", "r")
    if luaurc then
      return luaurc
    end
  end
end

local M = {}

---@param paths? string[]
---@return table<string, string>?
function M.aliases(paths)
  local luaurc = find_luaurc(paths or { "src", "lib" })
  if not luaurc then
    return
  end

  local success, contents = pcall(json.decode, luaurc:read "a")
  if not success then
    log.error("Failed to read '.luaurc': %s", contents)
    return
  end

  local aliases = vim.empty_dict()

  for alias, value in pairs(contents.aliases or {}) do
    aliases["@" .. alias] = value
  end

  return aliases
end

---@param opts luau-lsp.Config
function M.config(opts)
  require("luau-lsp.config").config(opts)
end

---@param opts luau-lsp.Config
function M.setup(opts)
  require("luau-lsp.config").config(opts)
end

return M
