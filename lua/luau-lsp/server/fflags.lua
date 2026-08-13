local async = require "luau-lsp.async"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"

local CURRENT_FFLAGS_URL =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCStudioApp"
local FFLAG_KINDS = { "FFlag", "FInt", "DFFlag", "DFInt" }

local M = {}

---@param callback fun(err: string?, fflags?: table<string, string>)
local fetch_fflags = async.wrap(function(callback)
  vim.net.request(CURRENT_FFLAGS_URL, {}, function(err, res)
    if err then
      callback(err)
      return
    end

    ---@cast res vim.net.request.Response
    local ok, content = pcall(vim.json.decode, res.body)
    if ok and content["applicationSettings"] then
      callback(nil, content["applicationSettings"])
    else
      callback "Invalid JSON or missing applicationSettings"
    end
  end)
end)

---@param result table<string, string>
---@param name string
---@param value string | number | boolean
local function add_fflag(result, name, value)
  for _, kind in ipairs(FFLAG_KINDS) do
    if vim.startswith(name, kind .. "Luau") then
      result[name:sub(#kind + 1)] = tostring(value)
      return
    end
  end

  if vim.startswith(name, "Luau") then
    result[name] = tostring(value)
  end
end

---@async
---@return table<string, string>
function M.resolve()
  local result = {}

  if config.get().fflags.sync then
    local err, fflags = fetch_fflags()
    if err then
      log.error("Failed to fetch current Luau FFlags: %s", err)
    end

    for name, value in pairs(fflags or {}) do
      add_fflag(result, name, value)
    end
  end

  if config.get().fflags.enable_new_solver then
    add_fflag(result, "LuauSolverV2", true)
  end

  for name, value in pairs(config.get().fflags.override) do
    add_fflag(result, name, value)
  end

  return result
end

return M
