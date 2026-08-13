local async = require "luau-lsp.async"
local config = require "luau-lsp.config"
local file_source = require "luau-lsp.server.file_source"
local util = require "luau-lsp.util"

local M = {}

---@param result table<string, luau-lsp.server.file_source.FileSource>
---@param name string
---@param source string
local function add_definition(result, name, source)
  local cache_name = name:gsub("^@", "")
  local def_name = vim.startswith(name, "@") and name or "@" .. name

  result[def_name] = {
    source = source,
    output = util.data_file("defs", cache_name .. ".d.luau"),
  }
end

---@return table<string, luau-lsp.server.file_source.FileSource>
local function definitions_from_config()
  local result = {}
  local definitions = config.get().types.definition_files

  if vim.islist(definitions) then
    for _, path in ipairs(definitions) do
      local name = vim.fs.basename(path):gsub("%.d?%.?luau?$", "")
      add_definition(result, name, path)
    end
  else
    for name, path in pairs(definitions) do
      add_definition(result, name, path)
    end
  end

  return result
end

---@return luau-lsp.server.file_source.FileSource[]
local function documentation_from_config()
  return vim.tbl_map(function(path)
    return {
      source = path,
      output = util.data_file("docs", vim.fs.basename(path)),
    }
  end, config.get().types.documentation_files)
end

---@async
---@param opts? { force?: boolean }
---@return table<string, string>
---@return string[]
function M.resolve(opts)
  opts = opts or {}

  local definition_sources = vim.tbl_deep_extend(
    "force",
    require("luau-lsp.roblox").definitions(),
    definitions_from_config()
  )

  local documentation_sources =
    vim.list_extend(require("luau-lsp.roblox").documentation(), documentation_from_config())

  local tasks = {}

  local definitions = {}
  for name, data in pairs(definition_sources) do
    ---@async
    table.insert(tasks, function()
      local path = file_source.resolve(data.source, data.output, opts)
      if path then
        definitions[name] = path
      end
    end)
  end

  local documentation = {}
  for _, data in ipairs(documentation_sources) do
    ---@async
    table.insert(tasks, function()
      local path = file_source.resolve(data.source, data.output, opts)
      if path then
        table.insert(documentation, path)
      end
    end)
  end

  async.join(tasks)
  return definitions, documentation
end

return M
