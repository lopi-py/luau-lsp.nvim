local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local FFLAG_KINDS = { "FFlag", "FInt", "DFFlag", "DFInt" }

---@class luau-lsp.Context
---@field cmd string
---@field fflags table<string, string>
---@field definitions table<string, string>
---@field documentation table<integer, string>
local Context = {}
Context.__index = Context

---@return luau-lsp.Context
function Context.new()
  return setmetatable({
    fflags = {},
    definitions = {},
    documentation = {},
  }, Context)
end

---@param name string
---@param value string|number|boolean
function Context:add_fflag(name, value)
  for _, kind in ipairs(FFLAG_KINDS) do
    if vim.startswith(name, kind .. "Luau") then
      self.fflags[name:sub(#kind + 1)] = tostring(value)
      return
    end
  end
  if vim.startswith(name, "Luau") then
    self.fflags[name] = tostring(value)
  end
end

---@param name string
---@param path string
function Context:add_definitions(name, path)
  if not name:find "^@" then
    name = "@" .. name
  end

  if util.is_file(path) then
    self.definitions[name] = path
  else
    log.warn(
      "Definitions file '%s' at '%s' does not exist, types will not be provided from this file",
      name,
      path
    )
  end
end

---@param path string
function Context:add_documentation(path)
  if util.is_file(path) then
    table.insert(self.documentation, path)
  else
    log.warn("Documentation file at '%s' does not exist", path)
  end
end

return Context
