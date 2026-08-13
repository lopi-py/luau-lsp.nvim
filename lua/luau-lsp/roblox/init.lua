local config = require "luau-lsp.config"
local util = require "luau-lsp.util"

local API_DOCS_URL = "https://luau-lsp.pages.dev/api-docs/en-us.json"
local LUAU_API_DOCS_URL = "https://luau-lsp.pages.dev/api-docs/luau-en-us.json"

local M = {}

local function global_types_url()
  return string.format(
    "https://luau-lsp.pages.dev/type-definitions/globalTypes.%s.d.luau",
    config.get().types.roblox_security_level
  )
end

local function global_types_file()
  return util.data_file(
    "defs",
    string.format("globalTypes.%s.d.luau", config.get().types.roblox_security_level)
  )
end

local function is_enabled()
  return config.get().platform.type == "roblox"
end

function M.definitions()
  if not is_enabled() then
    return {}
  end

  return {
    ["@roblox"] = { source = global_types_url(), output = global_types_file() },
  }
end

function M.documentation()
  if not is_enabled() then
    return { { source = LUAU_API_DOCS_URL, output = util.data_file("docs", "luau-api-docs.json") } }
  end
  return { { source = API_DOCS_URL, output = util.data_file("docs", "api-docs.json") } }
end

function M.setup()
  if not is_enabled() then
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
