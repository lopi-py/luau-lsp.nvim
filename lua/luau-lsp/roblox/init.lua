local async = require "plenary.async"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local API_DOCS =
  "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/api-docs/en-us.json"

local function global_types_url()
  return string.format(
    "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.%s.d.luau",
    config.get().types.roblox_security_level
  )
end

local function global_types_file()
  return util.storage_file(
    string.format("globalTypes.%s.d.luau", config.get().types.roblox_security_level)
  )
end

local function api_docs_file()
  return util.storage_file "api-docs.json"
end

local download_api = async.wrap(function(callback)
  local on_success = util.on_count(function()
    callback(true)
  end, 2)

  local on_error = util.on_count(function()
    callback(false)
  end, 2)

  curl.get(global_types_url(), {
    output = global_types_file(),
    callback = on_success,
    on_error = on_error,
    compressed = false,
  })

  curl.get(API_DOCS, {
    output = api_docs_file(),
    callback = on_success,
    on_error = on_error,
    compressed = false,
  })
end, 1)

local M = {}

---@async
---@param opts luau-lsp.ClientConfig
function M.prepare(opts)
  if config.get().platform.type ~= "roblox" then
    return
  end

  if not download_api() then
    if util.is_file(global_types_file()) and util.is_file(api_docs_file()) then
      log.error "Could not download roblox types, using local files"
    else
      log.error "Could not download roblox types, no local files found"
      return
    end
  end

  table.insert(opts.cmd, "--definitions=" .. global_types_file())
  table.insert(opts.cmd, "--docs=" .. api_docs_file())
end

function M.start()
  if config.get().sourcemap.enabled and config.get().sourcemap.autogenerate then
    require("luau-lsp.roblox.sourcemap").start()
  end

  if config.get().plugin.enabled then
    require("luau-lsp.roblox.studio").start()
  end
end

return M
