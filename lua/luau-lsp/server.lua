local Path = require "plenary.path"
local a = require "plenary.async"
local c = require "luau-lsp.config"
local compat = require "luau-lsp.compat"
local curl = require "plenary.curl"
local lsputil = require "lspconfig.util"
local util = require "luau-lsp.util"

local CURRENT_FFLAGS =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCDesktopClient"

local M = {}

local setup_server = function(opts)
  local bufnr = vim.api.nvim_get_current_buf()

  require("lspconfig").luau_lsp.setup(opts)
  require("lspconfig").luau_lsp.manager.try_add_wrapper(bufnr)
end

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

  local download_definition = a.wrap(function(callback)
    download(data.types, util.storage_file(name .. ".d.luau"), callback)
  end, 1)

  local download_documentation = a.wrap(function(callback)
    download(data.docs, util.storage_file(name .. ".json"), callback)
  end, 1)

  util.run_all({ download_definition, download_documentation }, function(result)
    callback(result[1][1], result[2][1])
  end)
end, 2)

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

local get_cmd = a.wrap(function(callback)
  a.run(function()
    local cmd = { "luau-lsp", "lsp" }

    local function add_definition_file(file)
      if Path:new(file):is_file() then
        table.insert(cmd, "--definitions=" .. file)
      end
    end

    local function add_documentation_file(file)
      if Path:new(file):is_file() then
        table.insert(cmd, "--docs=" .. file)
      end
    end

    if c.get().types.roblox then
      local definition_file, documentation_file = download_types "roblox"

      add_definition_file(definition_file)
      add_documentation_file(documentation_file)
    end

    for _, file in ipairs(c.get().types.definitionFiles) do
      add_definition_file(file)
    end

    for _, file in ipairs(c.get().types.documentationFiles) do
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
      table.insert(cmd, string.format("--flag:%s=%s", name, value))
    end

    if not c.get().fflags.enableByDefault then
      table.insert(cmd, "--no-flags-enabled")
    end

    return cmd
  end, callback)
end, 1)

local function resolve_opts(opts)
  local default_opts = {
    root_dir = lsputil.root_pattern {
      "*.project.json",
      ".luaurc",
      "aftman.toml",
      "selene.toml",
      "stylua.toml",
      "wally.toml",
      ".git",
    },
    settings = {
      ["luau-lsp"] = c.get(),
    },
  }

  return vim.tbl_deep_extend("force", default_opts, opts or {})
end

M.setup = a.void(function(opts)
  opts = resolve_opts(opts)

  c.setup(opts.settings["luau-lsp"])

  opts = vim.tbl_deep_extend("force", opts, {
    cmd = get_cmd(),
  })

  a.util.scheduler()

  require("luau-lsp.sourcemap").setup()
  setup_server(opts)
end)

return M
