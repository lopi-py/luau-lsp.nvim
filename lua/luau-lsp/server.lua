local Path = require "plenary.path"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local lspconfig = require "lspconfig"
local util = require "luau-lsp.util"

local CURRENT_FFLAGS =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCDesktopClient"

local format = string.format

local M = {}

local function get_flags(callback)
  curl.get {
    url = CURRENT_FFLAGS,
    accept = "application/json",
    callback = function(result)
      callback(vim.json.decode(result.body).applicationSettings)
    end,
    compressed = false,
  }
end

local setup_server = vim.schedule_wrap(function(cmd)
  local server = lspconfig.luau_lsp

  server.setup {
    cmd = cmd,
    filetypes = { "luau" },
    root_dir = lspconfig.util.root_pattern(config.get().rootFiles),
    settings = {
      ["luau-lsp"] = config.get(),
    },
  }

  server.manager.try_add_wrapper(vim.api.nvim_get_current_buf())
end)

function M.download_types(name, callback)
  local data = require("luau-lsp.types." .. name)

  local types_file = util.storage_file(name .. "Types.d.luau")
  local docs_file = util.storage_file(name .. "Docs.json")

  local on_finish = util.make_on_finish(2, function()
    table.insert(config.get().types.definitionFiles, types_file)
    table.insert(config.get().types.documentationFiles, docs_file)
    callback()
  end)

  curl.get(data.types, {
    output = types_file,
    callback = on_finish,
    compressed = false,
  })

  curl.get(data.docs, {
    output = docs_file,
    callback = on_finish,
    compressed = false,
  })
end

function M.setup()
  local function on_download()
    local cmd = { "luau-lsp", "lsp" }

    for _, file in ipairs(config.get().types.definitionFiles) do
      if Path:new(file):exists() then
        table.insert(cmd, "--definitions=" .. file)
      end
    end

    for _, file in ipairs(config.get().types.documentationFiles) do
      if Path:new(file):exists() then
        table.insert(cmd, "--docs=" .. file)
      end
    end

    local function on_fflags(fflags)
      local fflags = vim.tbl_extend("force", fflags, config.get().fflags.override)

      for name, value in pairs(fflags) do
        table.insert(cmd, format("--flag:%s=%s", name, value))
      end

      if not config.get().fflags.enableByDefault then
        table.insert(cmd, "--no-flags-enabled")
      end

      setup_server(cmd)
    end

    if config.get().fflags.sync then
      get_flags(function(result)
        local fflags = {}

        for name, value in pairs(result) do
          if name:match "^FFlagLuau" then
            fflags[name:sub(6)] = value
          end
        end

        on_fflags(fflags)
      end)
    else
      on_fflags {}
    end
  end

  if config.get().types.roblox then
    M.download_types("roblox", on_download)
  else
    on_download()
  end
end

return M
