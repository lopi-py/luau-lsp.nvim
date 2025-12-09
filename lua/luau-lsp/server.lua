local async = require "plenary.async"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local CURRENT_FFLAGS_URL =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCStudioApp"
local FFLAG_KINDS = { "FFlag", "FInt", "DFFlag", "DFInt" }

local M = {}

local fetch_fflags = async.wrap(function(callback)
  local function on_error(message)
    log.error("Failed to fetch current Luau FFlags: %s", message)
    callback {}
  end

  curl.get(CURRENT_FFLAGS_URL, {
    callback = function(result)
      local ok, content = pcall(vim.json.decode, result.body)
      if ok and content["applicationSettings"] then
        callback(content["applicationSettings"])
      else
        on_error "Invalid JSON or missing applicationSettings"
      end
    end,
    on_error = function(result)
      on_error(result.stderr)
    end,
  })
end, 1)

---@param fflags table<string, string>
---@param name string
---@param value boolean|number|string
local function append_fflag(fflags, name, value)
  for _, kind in ipairs(FFLAG_KINDS) do
    if vim.startswith(name, kind .. "Luau") then
      fflags[name:sub(#kind + 1)] = tostring(value)
      return
    end
  end
end

---@async
---@return table<string, string>
local function get_fflags()
  local fflags = {}

  if config.get().fflags.sync then
    for name, value in pairs(fetch_fflags()) do
      append_fflag(fflags, name, value)
    end
  end

  if config.get().fflags.enable_new_solver then
    fflags["LuauSolverV2"] = "true"
  end

  for name, value in pairs(config.get().fflags.override) do
    append_fflag(fflags, name, value)
  end

  return fflags
end

---@async
---@return string[]
local function get_cmd()
  local cmd = { config.get().server.path, "lsp" }

  require("luau-lsp.roblox").prepare(cmd)

  for _, path in ipairs(config.get().types.definition_files) do
    path = vim.fs.normalize(path)
    if util.is_file(path) then
      table.insert(cmd, "--definitions=" .. path)
    else
      log.warn(
        "Definitions file at '%s' does not exist, types will not be provided from this file",
        path
      )
    end
  end

  for _, path in ipairs(config.get().types.documentation_files) do
    path = vim.fs.normalize(path)
    if util.is_file(path) then
      table.insert(cmd, "--docs=" .. path)
    else
      log.warn("Documentations file at '%s' does not exist", path)
    end
  end

  if not config.get().fflags.enable_by_default then
    table.insert(cmd, "--no-flags-enabled")
  end

  return cmd
end

local function start()
  vim.lsp.enable "luau-lsp"

  require("luau-lsp.roblox").start()

  -- HACK: nvim 0.11 does not start the server right after enabling
  if vim.fn.has "nvim-0.12" == 0 then
    vim
      .iter(vim.api.nvim_list_bufs())
      :filter(function(bufnr)
        return vim.bo[bufnr].filetype == "luau"
      end)
      :each(function(bufnr)
        vim.api.nvim_exec_autocmds("FileType", {
          group = "nvim.lsp.enable",
          buffer = bufnr,
          modeline = false,
        })
      end)
  end
end

function M.setup()
  async.run(function()
    vim.lsp.config("luau-lsp", {
      cmd = get_cmd(),
      init_options = { fflags = get_fflags() },
    })
  end, vim.schedule_wrap(start))
end

return M
