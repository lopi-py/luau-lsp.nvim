local Path = require "plenary.path"
local async = require "plenary.async"
local c = require "luau-lsp.config"
local compat = require "luau-lsp.compat"
local curl = require "plenary.curl"
local util = require "luau-lsp.util"

local channel = async.control.channel
local run = async.run
local scheduler = async.util.scheduler
local void = async.void
local wrap = async.wrap

local CURRENT_FFLAGS =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCDesktopClient"

local M = {}

local download = function(url, output, callback)
  curl.get(url, {
    output = output,
    callback = function()
      callback(output)
    end,
    compressed = false,
  })
end

local download_types = wrap(function(name, callback)
  local data = require("luau-lsp.types." .. name)
  local tx, rx = channel.mpsc()

  download(data.types, util.storage_file(name .. ".d.luau"), tx.send)
  download(data.docs, util.storage_file(name .. ".json"), tx.send)

  run(function()
    callback(rx.recv(), rx.recv())
  end)
end, 2)

local get_fflags = wrap(function(callback)
  curl.get {
    url = CURRENT_FFLAGS,
    accept = "application/json",
    callback = function(result)
      callback(vim.json.decode(result.body).applicationSettings)
    end,
    compressed = false,
  }
end, 1)

local function get_args()
  local args = {}

  local function add_definition_file(file)
    if Path:new(file):is_file() then
      table.insert(args, "--definitions=" .. file)
    end
  end

  local function add_documentation_file(file)
    if Path:new(file):is_file() then
      table.insert(args, "--docs=" .. file)
    end
  end

  if c.get().types.roblox then
    local definition_file, documentation_file = download_types "roblox"

    add_definition_file(definition_file)
    add_documentation_file(documentation_file)
  end

  for _, file in ipairs(c.get().types.definition_files) do
    add_definition_file(file)
  end

  for _, file in ipairs(c.get().types.documentation_files) do
    add_documentation_file(file)
  end

  local current_fflags = {}

  if c.get().fflags.sync then
    compat
      .iter(get_fflags())
      :filter(function(name)
        return name:match "^FFlagLuau"
      end)
      :map(function(name, value)
        return name:sub(6), value
      end)
      :each(function(name, value)
        current_fflags[name] = value
      end)
  end

  local fflags = vim.tbl_extend("force", current_fflags, c.get().fflags.override)

  for name, value in pairs(fflags) do
    table.insert(args, string.format("--flag:%s=%s", name, value))
  end

  if not c.get().fflags.enable_by_default then
    table.insert(args, "--no-flags-enabled")
  end

  return args
end

M.setup = void(function()
  local opts = vim.deepcopy(c.get().server)
  opts.cmd = vim.list_extend(opts.cmd, get_args())

  scheduler()
  require("lspconfig").luau_lsp.setup(opts)
  require("lspconfig").luau_lsp.manager.try_add()
end)

return M
