local async = require "plenary.async"
local curl = require "plenary.curl"
local util = require "luau-lsp.util"

local API_DOCS =
  "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/api-docs/en-us.json"
local SECURITY_LEVELS = {
  "None",
  "LocalUserSecurity",
  "PluginSecurity",
  "RobloxScriptSecurity",
}

local function global_types_url(security_level)
  return string.format(
    "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.%s.d.luau",
    security_level
  )
end

local function global_types_file(security_level)
  return util.storage_file(string.format("globalTypes.%s.d.luau", security_level))
end

local function api_docs_file()
  return util.storage_file "api-docs.json"
end

local M = {}

---@type fun(security_level:string):string,string
M.download_api = async.wrap(function(security_level, callback)
  assert(
    vim.list_contains(SECURITY_LEVELS, security_level),
    "invalid security level: " .. security_level
  )

  local on_download = util.fcounter(2, function()
    callback(global_types_file(security_level), api_docs_file())
  end)

  curl.get(API_DOCS, {
    output = api_docs_file(),
    callback = on_download,
    compressed = false,
  })

  curl.get(global_types_url(security_level), {
    output = global_types_file(security_level),
    callback = on_download,
    compressed = false,
  })
end, 2)

return M
