local Path = require "plenary.path"
local async = require "plenary.async"
local compat = require "luau-lsp.compat"
local config = require "luau-lsp.config"
local curl = require "plenary.curl"
local log = require "luau-lsp.log"

local CURRENT_FFLAGS =
  "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCDesktopClient"

local get_fflags = async.wrap(function(callback)
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

local function get_server_args()
  local args = {}

  local function add_definition_file(file)
    if Path:new(file):is_file() then
      table.insert(args, "--definitions=" .. file)
    else
      log.warn(
        "Definitions file at `%s` does not exist, types will not be provided from this file",
        file
      )
    end
  end

  local function add_documentation_file(file)
    if Path:new(file):is_file() then
      table.insert(args, "--docs=" .. file)
    else
      log.warn("Documentations file at `%s` does not exist", file)
    end
  end

  for _, file in ipairs(config.get().types.definition_files) do
    add_definition_file(file)
  end

  for _, file in ipairs(config.get().types.documentation_files) do
    add_documentation_file(file)
  end

  if not config.get().fflags.enable_by_default then
    table.insert(args, "--no-flags-enabled")
  end

  local fflags = {}

  if config.get().fflags.sync then
    compat
      .iter(get_fflags())
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

  fflags = vim.tbl_extend("force", fflags, config.get().fflags.override)

  for name, value in pairs(fflags) do
    table.insert(args, string.format("--flag:%s=%s", name, value))
  end

  if config.get().types.roblox then
    local roblox = require "luau-lsp.roblox"
    local definition_file, documentation_file = roblox.download_api()

    if definition_file and documentation_file then
      add_definition_file(definition_file)
      add_documentation_file(documentation_file)
    end
  end

  return args
end

-- patch shared settings between the client extension and the server
local function patch_server_settings(settings)
  return vim.tbl_deep_extend("force", settings, {
    ["luau-lsp"] = {
      sourcemap = {
        enabled = config.get().sourcemap.enabled,
      },
    },
  })
end

--- neovim does not support diagnostic's relatedDocuments, but push-based diagnostics should work
--- fine, this should also avoid the error "server not yet received configuration for diagnostics"
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

    local write_error = client.write_error
    client.write_error = function(self, code, err)
      if err.error.message == "server not yet received configuration for diagnostics" then
        return
      end
      write_error(self, code, err)
    end

    client.server_capabilities.diagnosticProvider = nil
  end
end

local function setup_server()
  local bufnr = vim.api.nvim_get_current_buf()
  local opts = vim.deepcopy(config.get().server)

  opts.cmd = vim.list_extend(opts.cmd, get_server_args())
  opts.settings = patch_server_settings(opts.settings)

  force_push_diagnostics(opts)

  vim.schedule(function()
    require("lspconfig").luau_lsp.setup(opts)
    require("lspconfig").luau_lsp.manager:try_add_wrapper(bufnr)
  end)
end

local function lock_config()
  local function cannot_be_changed(path)
    config.on(path, function()
      log.warn("`%s` cannot be changed once the server is started", path)
    end)
  end

  cannot_be_changed "fflags"
  cannot_be_changed "sourcemap.enabled"
  cannot_be_changed "types"
end

local M = {}

---@param path string
---@param marker string[]|fun(name:string):boolean
---@return string?
function M.find_root(path, marker)
  local paths = vim.fs.find(marker, {
    upward = true,
    path = path,
  })

  if #paths == 0 then
    return nil
  end

  return vim.fs.dirname(paths[1])
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    once = true,
    pattern = config.get().server.filetypes or { "luau" },
    callback = function()
      lock_config()
      async.run(setup_server)
    end,
  })
end

return M
