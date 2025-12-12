local Context = require "luau-lsp.context"
local async = require "plenary.async"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local CURRENT_FFLAGS_URL =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCStudioApp"

local CACHE_TTL = 24 * 60 * 60

---@param path string
local function is_cache_valid(path)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return false
  end
  return os.time() - stat.mtime.sec < CACHE_TTL
end

---@param name string
---@return string
local function definitions_path(name)
  name = name:gsub("^@", "")
  return util.storage_file("defs", name .. ".d.luau")
end

---@param path string
---@return string
local function documentation_path(path)
  return util.storage_file("docs", vim.fs.basename(path))
end

local M = {}

---@param callback fun(fflags: table<string, string>)
local fetch_fflags = async.wrap(function(callback)
  local function on_error(message)
    log.error("Failed to fetch current Luau FFlags: %s", message)
    callback {}
  end

  curl.get(CURRENT_FFLAGS_URL, {
    callback = vim.schedule_wrap(function(result)
      local ok, content = pcall(vim.json.decode, result.body)
      if ok and content["applicationSettings"] then
        callback(content["applicationSettings"])
      else
        on_error "Invalid JSON or missing applicationSettings"
      end
    end),
    on_error = vim.schedule_wrap(function(result)
      on_error(result.stderr)
    end),
  })
end, 1)

---@async
---@param ctx luau-lsp.Context
local function add_fflags_to_context(ctx)
  if config.get().fflags.sync then
    for name, value in pairs(fetch_fflags()) do
      ctx:add_fflag(name, value)
    end
  end

  if config.get().fflags.enable_new_solver then
    ctx:add_fflag("LuauSolverV2", true)
  end

  for name, value in pairs(config.get().fflags.override) do
    ctx:add_fflag(name, value)
  end
end

---@param source string
---@param output string
---@param force boolean
---@param callback fun(path?: string)
local function resolve_remote_file(source, output, force, callback)
  if not force and is_cache_valid(output) then
    callback(output)
    return
  end

  util.download_file(source, output, function(err, path)
    if path then
      callback(path)
    elseif util.is_file(output) then
      log.warn("Failed to download file from '%s', using local version: %s", source, err)
      callback(output)
    else
      log.error("Failed to download file from '%s': %s", source, err)
      callback()
    end
  end)
end

---@param source string
---@param output string
---@param force boolean
---@param callback fun(path: string?)
local function resolve_file(source, output, force, callback)
  if source:find "^https?://" then
    resolve_remote_file(source, output, force, callback)
  else
    callback(vim.fs.normalize(source))
  end
end

---@param path string
local function get_package_name(path)
  local filename = vim.fs.basename(path)
  return filename:match "^(.-)%.d?%.?luau?$" or filename
end

local function normalize_definitions()
  local result = {}
  local definitions = config.get().types.definition_files

  if #definitions > 0 then
    for _, path in ipairs(definitions) do
      local name = get_package_name(path)
      result[name] = { source = path, output = definitions_path(name) }
    end
    return result
  end

  for name, path in pairs(definitions) do
    result[name] = { source = path, output = definitions_path(name) }
  end
  return result
end

local function normalize_documentation()
  local result = {}
  local documentation = config.get().types.documentation_files
  for _, path in ipairs(documentation) do
    table.insert(result, { source = path, output = documentation_path(path) })
  end
  return result
end

---@async
---@param ctx luau-lsp.Context
---@param force boolean
local function add_definitions_to_context(ctx, force)
  local roblox_defs, roblox_docs = require("luau-lsp.roblox").definitions()
  local config_defs, config_docs = normalize_definitions(), normalize_documentation()

  local definitions = vim.tbl_extend("force", roblox_defs or {}, config_defs)
  local documentation = vim.list_extend(roblox_docs or {}, config_docs)

  local futures = {}

  for name, data in pairs(definitions) do
    table.insert(
      futures,
      async.wrap(function(callback)
        resolve_file(data.source, data.output, force, function(path)
          if path then
            ctx:add_definitions(name, path)
          end
          callback()
        end)
      end, 1)
    )
  end

  for _, data in ipairs(documentation) do
    table.insert(
      futures,
      async.wrap(function(callback)
        resolve_file(data.source, data.output, force, function(path)
          if path then
            ctx:add_documentation(path)
          end
          callback()
        end)
      end, 1)
    )
  end

  async.util.join(futures)
end

---@private
---@param ctx luau-lsp.Context
---@return string[]
function M.build_cmd(ctx)
  local cmd = { config.get().server.path, "lsp" }

  for name, path in pairs(ctx.definitions) do
    if util.is_file(path) then
      table.insert(cmd, "--definitions:" .. name .. "=" .. path)
    else
      log.warn("Definitions file '%s' at '%s' does not exist", name, path)
    end
  end

  for _, path in ipairs(ctx.documentation) do
    if util.is_file(path) then
      table.insert(cmd, "--docs=" .. path)
    else
      log.warn("Documentation file at '%s' does not exist", path)
    end
  end

  if not config.get().fflags.enable_by_default then
    table.insert(cmd, "--no-flags-enabled")
  end

  local base_luaurc = config.get().server.base_luaurc
  if base_luaurc then
    base_luaurc = vim.fs.normalize(base_luaurc)
    if util.is_file(base_luaurc) then
      table.insert(cmd, "--base-luaurc=" .. base_luaurc)
    else
      log.warn("Base .luaurc file at '%s' does not exist", base_luaurc)
    end
  end

  return cmd
end

M.download_api = async.void(function()
  local ctx = Context.new()
  add_definitions_to_context(ctx, true)
  log.info "Definitions files have been updated, reload server to take effect"
end)

M.setup = async.void(function()
  local ctx = Context.new()

  add_definitions_to_context(ctx, false)
  add_fflags_to_context(ctx)

  vim.lsp.config("luau-lsp", {
    cmd = M.build_cmd(ctx),
    init_options = { fflags = ctx.fflags },
  })

  vim.lsp.enable "luau-lsp"
  require("luau-lsp.roblox").start()
end)

return M
