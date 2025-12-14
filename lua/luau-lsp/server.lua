local Context = require "luau-lsp.context"
local async = require "luau-lsp.async"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"
local resolver = require "luau-lsp.resolver"
local util = require "luau-lsp.util"

local CURRENT_FFLAGS_URL =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCStudioApp"

local M = {}

---@param callback fun(err: string?, fflags: table<string, string>?)
local fetch_fflags = async.wrap(function(callback)
  util.request(CURRENT_FFLAGS_URL, nil, function(err, res)
    if err then
      callback(err)
      return
    end

    local ok, content = pcall(vim.json.decode, res.body)
    if ok and content["applicationSettings"] then
      callback(nil, content["applicationSettings"])
    else
      callback "Invalid JSON or missing applicationSettings"
    end
  end)
end)

---@async
---@param ctx luau-lsp.Context
local function add_fflags_to_context(ctx)
  if config.get().fflags.sync then
    local err, fflags = fetch_fflags()
    if err then
      log.error("Failed to fetch current Luau FFlags: %s", err)
    end

    for name, value in pairs(fflags or {}) do
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

local function normalize_definitions()
  local result = {}
  local definitions = config.get().types.definition_files

  ---@param path string
  local function get_package_name(path)
    local filename = vim.fs.basename(path)
    return filename:match "^(.-)%.d?%.?luau?$" or filename
  end

  if #definitions > 0 then
    for _, path in ipairs(definitions) do
      local name = get_package_name(path)
      result[name] = { source = path, output = definitions_path(name) }
    end
  else
    for name, path in pairs(definitions) do
      result[name] = { source = path, output = definitions_path(name) }
    end
  end

  return result
end

local function normalize_documentation()
  local result = {}
  for _, path in ipairs(config.get().types.documentation_files) do
    table.insert(result, { source = path, output = documentation_path(path) })
  end
  return result
end

---@async
---@param ctx luau-lsp.Context
---@param opts? { force: boolean? }
local function add_definitions_to_context(ctx, opts)
  opts = opts or {}

  local roblox_defs, roblox_docs = require("luau-lsp.roblox").definitions()
  local config_defs, config_docs = normalize_definitions(), normalize_documentation()

  local definitions = vim.tbl_extend("force", roblox_defs, config_defs)
  local documentation = vim.list_extend(roblox_docs, config_docs)

  local tasks = {}

  for name, data in pairs(definitions) do
    table.insert(tasks, function()
      local path = resolver.resolve_file(data.source, data.output, opts)
      if path then
        ctx:add_definitions(name, path)
      end
    end)
  end

  for _, data in ipairs(documentation) do
    table.insert(tasks, function()
      local path = resolver.resolve_file(data.source, data.output, opts)
      if path then
        ctx:add_documentation(path)
      end
    end)
  end

  async.join(tasks)
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
  add_definitions_to_context(ctx, { force = true })
  log.info "Definitions files have been updated, reload server to take effect"
end)

M.setup = async.void(function()
  local ctx = Context.new()

  async.join {
    function()
      add_fflags_to_context(ctx)
    end,
    function()
      add_definitions_to_context(ctx)
    end,
  }

  vim.lsp.config("luau-lsp", {
    cmd = M.build_cmd(ctx),
    init_options = { fflags = ctx.fflags },
  })

  vim.lsp.enable "luau-lsp"

  require("luau-lsp.roblox").setup()
end)

return M
