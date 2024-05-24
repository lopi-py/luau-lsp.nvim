local async = require "plenary.async"
local compat = require "luau-lsp.compat"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local API_DOCS =
  "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/api-docs/en-us.json"

local uv = compat.uv

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
  local on_success = util.fcounter(2, function()
    callback(true)
  end)

  local on_error = util.fcounter(2, function()
    callback(false)
  end)

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

function M.is_enabled()
  return config.get().platform.type == "roblox"
end

function M.start()
  if not M.is_enabled() then
    return
  end

  if config.get().sourcemap.enabled and config.get().sourcemap.autogenerate then
    require("luau-lsp.roblox.sourcemap").start()
  end

  if config.get().plugin.enabled then
    require("luau-lsp.roblox.studio").start()
  end
end

---@async
function M.setup(opts)
  if not M.is_enabled() then
    return
  end

  vim.schedule(function()
    require("luau-lsp.roblox.sourcemap").setup()
    require("luau-lsp.roblox.studio").setup()
  end)

  if not download_api() then
    if uv.fs_stat(global_types_file()) and uv.fs_stat(api_docs_file()) then
      log.error "Could not download roblox types, using local files"
    else
      log.error "Could not download roblox types, no local files found"
      return
    end
  end

  table.insert(opts.cmd, "--definitions=" .. global_types_file())
  table.insert(opts.cmd, "--docs=" .. api_docs_file())
end

return M
