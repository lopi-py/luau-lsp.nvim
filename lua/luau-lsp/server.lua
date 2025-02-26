local async = require "plenary.async"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local CURRENT_FFLAGS_URL =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCDesktopClient"
local FFLAG_KINDS = { "FFlag", "FInt", "DFFlag", "DFInt" }

---@type integer[]
local pending_buffers = {}

local fetch_fflags = async.wrap(function(callback)
  local function on_error(message)
    log.error("Failed to fetch current Luau FFlags: %s", message)
    callback {}
  end

  curl.get(CURRENT_FFLAGS_URL, {
    callback = function(result)
      local ok, content = pcall(vim.json.decode, result.body)
      if ok then
        callback(content.applicationSettings)
      else
        on_error(content)
      end
    end,
    on_error = function(result)
      on_error(result.stderr)
    end,
  })
end, 1)

---@async
---@return table<string, string>
local function get_fflags()
  local fflags = {}

  if config.get().fflags.sync then
    for name, value in pairs(fetch_fflags()) do
      for _, kind in ipairs(FFLAG_KINDS) do
        if vim.startswith(name, kind .. "Luau") then
          fflags[name:sub(#kind + 1)] = value
        end
      end
    end
  end

  if config.get().fflags.enable_new_solver then
    fflags["LuauSolverV2"] = "true"
    fflags["LuauNewSolverPopulateTableLocations"] = "true"
    fflags["LuauNewSolverPrePopulateClasses"] = "true"
  end

  return vim.tbl_deep_extend("force", fflags, config.get().fflags.override)
end

---@async
---@return string[]
local function get_cmd()
  local cmd = vim.deepcopy(config.get().server.cmd)
  cmd[1] = vim.fn.exepath(cmd[1])

  require("luau-lsp.roblox").prepare(cmd)

  for _, definition_file in ipairs(config.get().types.definition_files) do
    definition_file = vim.fs.normalize(definition_file)
    if util.is_file(definition_file) then
      table.insert(cmd, "--definitions=" .. definition_file)
    else
      log.warn(
        "Definitions file at '%s' does not exist, types will not be provided from this file",
        definition_file
      )
    end
  end

  for _, documentation_file in ipairs(config.get().types.documentation_files) do
    documentation_file = vim.fs.normalize(documentation_file)
    if util.is_file(documentation_file) then
      table.insert(cmd, "--docs=" .. documentation_file)
    else
      log.warn("Documentations file at '%s' does not exist", documentation_file)
    end
  end

  if not config.get().fflags.enable_by_default then
    table.insert(cmd, "--no-flags-enabled")
  end

  return cmd
end

--- Patch shared settings between the client extension and the server
local function get_settings()
  return {
    ["luau-lsp"] = {
      platform = {
        type = config.get().platform.type,
      },
      sourcemap = {
        enabled = config.get().sourcemap.enabled,
        sourcemapFile = config.get().sourcemap.sourcemap_file,
      },
    },
  }
end

--- Neovim does not support diagnostic's relatedDocuments, but push-based diagnostics should work
--- fine
---
---@param opts vim.lsp.ClientConfig
local function force_push_diagnostics(opts)
  local capabilities = opts.capabilities or vim.lsp.protocol.make_client_capabilities()
  opts.capabilities = vim.tbl_deep_extend("force", capabilities, {
    textDocument = {
      diagnostic = vim.NIL,
    },
  })

  local on_init = opts.on_init
  opts.on_init = function(client, result)
    if on_init then
      on_init(client, result)
    end
    client.server_capabilities.diagnosticProvider = nil
  end
end

---@param client_id number
local function attach_pending_buffers(client_id)
  for _, bufnr in ipairs(pending_buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.lsp.buf_attach_client(bufnr, client_id)
    end
  end
  pending_buffers = {}
end

local function start_language_server()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  local opts = vim.deepcopy(config.get().server) --[[@as vim.lsp.ClientConfig]]
  opts.name = "luau-lsp"
  opts.cmd = get_cmd()
  opts.root_dir = opts.root_dir(bufname)
  opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, get_settings())
  opts.init_options = {
    fflags = get_fflags(),
  }

  force_push_diagnostics(opts)

  local client_id = vim.lsp.start_client(opts)
  if not client_id then
    log.error "luau-lsp executable not found"
    return
  end

  vim.schedule(function()
    require("luau-lsp.roblox").start()
    attach_pending_buffers(client_id)
  end)
end

---@param bufnr integer
---@return boolean
local function is_luau_file(bufnr)
  return vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype == "luau"
end

local M = {}

---@param bufnr? number
function M.start(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not is_luau_file(bufnr) then
    return
  end

  local client = util.get_client()
  if client then
    vim.lsp.buf_attach_client(bufnr, client.id)
    return
  end

  if vim.list_contains(pending_buffers, bufnr) then
    return
  end

  if #pending_buffers == 0 then
    async.run(start_language_server)
  end

  table.insert(pending_buffers, bufnr)
end

function M.stop()
  local client = util.get_client()
  if client then
    client.stop()
  end
end

function M.restart()
  local client = util.get_client()
  if not client then
    return
  end

  client.stop()

  local buffers = vim.lsp.get_buffers_by_client_id(client.id)

  local timer = vim.uv.new_timer()
  timer:start(500, 100, function()
    if client.is_stopped() then
      timer:stop()
      vim.iter(buffers):each(vim.schedule_wrap(M.start))
    end
  end)
end

return M
