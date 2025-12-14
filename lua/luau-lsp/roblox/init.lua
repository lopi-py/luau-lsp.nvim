local config = require "luau-lsp.config"
local util = require "luau-lsp.util"

local API_DOCS_URL = "https://luau-lsp.pages.dev/api-docs/en-us.json"

local M = {}

local function global_types_url()
  return string.format(
    "https://luau-lsp.pages.dev/type-definitions/globalTypes.%s.d.luau",
    config.get().types.roblox_security_level
  )
end

local function global_types_file()
  return util.storage_file(
    "defs",
    string.format("globalTypes.%s.d.luau", config.get().types.roblox_security_level)
  )
end

local function api_docs_file()
  return util.storage_file("docs", "api-docs.json")
end

function M.definitions()
  if config.get().platform.type ~= "roblox" then
    return {}, {}
  end

  local definitions = {
    ["@roblox"] = {
      source = global_types_url(),
      output = global_types_file(),
    },
  }

  local documentation = { {
    source = API_DOCS_URL,
    output = api_docs_file(),
  } }

  return definitions, documentation
end

function M.setup()
  if config.get().platform.type ~= "roblox" then
    return
  end

  if config.get().sourcemap.enabled and config.get().sourcemap.autogenerate then
    require("luau-lsp.roblox.sourcemap").start()
  end

  if config.get().plugin.enabled then
    require("luau-lsp.roblox.studio").start()
  end
end

return M
