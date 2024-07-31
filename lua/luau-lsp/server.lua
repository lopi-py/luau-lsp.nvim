local Job = require "plenary.job"
local async = require "plenary.async"
local compat = require "luau-lsp.compat"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local CURRENT_FFLAGS =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCDesktopClient"

local pending_buffers = {}

local fetch_fflags = async.wrap(function(callback)
  curl.get {
    url = CURRENT_FFLAGS,
    accept = "application/json",
    callback = function(result)
      callback(vim.json.decode(result.body).applicationSettings)
    end,
    on_error = function()
      log.error "Could not fetch the latest Luau FFlags"
      callback {}
    end,
    compressed = false,
  }
end, 1)

---@async
---@return table<string, string>
local function get_fflags()
  local fflags = {}

  if config.get().fflags.sync then
    compat
      .iter(fetch_fflags())
      :filter(function(name)
        return name:match "^FFlagLuau"
      end)
      :map(function(name, value)
        ---@diagnostic disable-next-line: redundant-return-value
        return name:sub(6), value
      end)
      :each(function(name, value)
        fflags[name] = value
      end)
  end

  return vim.tbl_deep_extend("force", fflags, config.get().fflags.override)
end

---@return string[]
local function get_cmd()
  local cmd = vim.deepcopy(config.get().server.cmd)

  for _, definition_file in ipairs(config.get().types.definition_files) do
    definition_file = vim.fs.normalize(definition_file)
    if util.is_file(definition_file) then
      table.insert(cmd, "--definitions=" .. definition_file)
    else
      log.warn(
        "Definitions file at `%s` does not exist, types will not be provided from this file",
        definition_file
      )
    end
  end

  for _, documentation_file in ipairs(config.get().types.documentation_files) do
    documentation_file = vim.fs.normalize(documentation_file)
    if util.is_file(documentation_file) then
      table.insert(cmd, "--docs=" .. documentation_file)
    else
      log.warn("Documentations file at `%s` does not exist", documentation_file)
    end
  end

  if not config.get().fflags.enable_by_default then
    table.insert(cmd, "--no-flags-enabled")
  end

  return cmd
end

---@return string?
local function get_root_dir()
  local bufnr = vim.api.nvim_get_current_buf()
  return config.get().server.root_dir(vim.api.nvim_buf_get_name(bufnr))
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
      },
    },
  }
end

--- Neovim does not support diagnostic's relatedDocuments, but push-based diagnostics should work
--- fine
---
---@param opts luau-lsp.ClientConfig
local function force_push_diagnostics(opts)
  opts.capabilities = vim.tbl_deep_extend("force", opts.capabilities or {}, {
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

---@async
---@return number
local function start_language_server()
  local opts = vim.tbl_deep_extend("force", config.get().server, {
    name = "luau-lsp",
    cmd = get_cmd(),
    root_dir = get_root_dir(),
    settings = get_settings(),
    init_options = { fflags = get_fflags() },
  })

  force_push_diagnostics(opts)
  require("luau-lsp.roblox").prepare(opts)

  local client_id = vim.lsp.start_client(opts)
  assert(client_id, "could not start luau-lsp")

  vim.schedule(function()
    require("luau-lsp.roblox").start()
  end)

  return client_id
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

---@param bufnr number
---@return boolean
local function is_luau_file(bufnr)
  return vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype == "luau"
end

local M = {}

---@return vim.Version
function M.version()
  local result = Job:new({ command = "luau-lsp", args = { "--version" } }):sync()

  local version = vim.version.parse(result[1])
  assert(version, "could not parse luau-lsp version")

  return version
end

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

  if compat.list_contains(pending_buffers, bufnr) then
    return
  end

  if #pending_buffers == 0 then
    async.run(start_language_server, vim.schedule_wrap(attach_pending_buffers))
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

  local timer = compat.uv.new_timer()
  timer:start(500, 100, function()
    if client.is_stopped() then
      timer:stop()
      compat.iter(buffers):each(vim.schedule_wrap(M.start))
    end
  end)
end

---@param path string
---@param marker string[] | fun(name: string): boolean
---@return string?
function M.root(path, marker)
  local paths = vim.fs.find(marker, {
    upward = true,
    path = path,
  })

  if #paths == 0 then
    return nil
  end

  return vim.fs.dirname(paths[1])
end

return M
