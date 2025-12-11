local FFLAG_KINDS = { "FFlag", "FInt", "DFFlag", "DFInt" }

---@class luau-lsp.Context
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
  self.definitions[name] = path
end

---@param path string
function Context:add_documentation(path)
  table.insert(self.documentation, path)
end

return Context
