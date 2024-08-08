local M = {}

---@return table<string, string>?
function M.aliases()
  local luaurc = io.open(".luaurc", "r")
  if not luaurc then
    return
  end

  local json = require "luau-lsp.json"
  local log = require "luau-lsp.log"

  local success, contents = pcall(json.decode, luaurc:read "a")
  if not success then
    log.error("Could not read `.luaurc`: %s", contents)
    return
  end

  local aliases = {}

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
