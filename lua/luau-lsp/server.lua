local Path = require "plenary.path"
local a = require "plenary.async"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local lspconfig = require "lspconfig"
local util = require "luau-lsp.util"
local CURRENT_FFLAGS =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCDesktopClient"

local M = {}

local function setup_server(cmd)
  local server = lspconfig.luau_lsp

  server.setup {
    cmd = cmd,
    root_dir = lspconfig.util.root_pattern(config.get().rootFiles),
    settings = {
      ["luau-lsp"] = config.get(),
    },
  }

  server.manager.try_add_wrapper(vim.api.nvim_get_current_buf())
end

local get_fflags = a.wrap(function(callback)
  curl.get {
    url = CURRENT_FFLAGS,
    accept = "application/json",
    callback = function(result)
      callback(vim.json.decode(result.body).applicationSettings)
    end,
    compressed = false,
  }
end, 1)

local download = a.wrap(function(url, output, callback)
  curl.get(url, {
    output = output,
    callback = function()
      callback(output)
    end,
    compressed = false,
  })
end, 3)

local download_types = a.wrap(function(name, callback)
  local data = require("luau-lsp.types." .. name)

  local download_types = a.wrap(function(callback)
    download(data.types, util.storage_file(name .. ".d.luau"), callback)
  end, 1)

  local download_docs = a.wrap(function(callback)
    download(data.docs, util.storage_file(name .. ".json"), callback)
  end, 1)

  util.run_all({ download_types, download_docs }, function(result)
    callback(result[1][1], result[2][1])
  end)
end, 2)

M.setup = a.void(function()
  local cmd = { "luau-lsp", "lsp" }

  local function add_definition_file(file)
    if Path:new(file):exists() then
      table.insert(cmd, "--definitions=" .. file)
    end
  end

  local function add_documentation_file(file)
    if Path:new(file):exists() then
      table.insert(cmd, "--docs=" .. file)
    end
  end

  if config.get().types.roblox then
    local definition_file, documentation_file = download_types "roblox"

    add_definition_file(definition_file)
    add_documentation_file(documentation_file)
  end

  for _, file in ipairs(config.get().types.definitionFiles) do
    add_definition_file(file)
  end

  for _, file in ipairs(config.get().types.documentationFiles) do
    add_documentation_file(file)
  end

  local current_fflags = {}

  if config.get().fflags.sync then
    vim
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

  local fflags = vim.tbl_extend("force", current_fflags, config.get().fflags.override)

  for name, value in pairs(fflags) do
    table.insert(cmd, string.format("--flag:%s=%s", name, value))
  end

  if not config.get().fflags.enableByDefault then
    table.insert(cmd, "--no-flags-enabled")
  end

  a.util.scheduler()
  setup_server(cmd)
end)

return M
