---@class LuauLspConfig
local DEFAULTS = {
  ---@type string[] @Root files to find workspace folder
  rootFiles = {
    "*.project.json",
    ".luaurc",
    "aftman.toml",
    "selene.toml",
    "stylua.toml",
    "wally.toml",
    ".git",
  },

  sourcemap = {
    --- Whether Rojo sourcemap parsing is enabled
    enabled = false,
    --- Automatically run the `rojo sourcemap` command to regenerate sourcemaps on changes
    autogenerate = false,
    --- Path to the Rojo executable. If not provided, attempts to run `rojo` in the workspace directory, so it must be available on the PATH
    rojoPath = "rojo",
    --- The name of the Rojo project file to generate a sourcemap for. Only applies if `sourcemap.autogenerate` is enabled
    rojoProjectFile = "default.project.json",
    --- Include non-script instances in the generated sourcemap
    includeNonScripts = true,
  },

  types = {
    ---@type string[] @A list of paths to definition files to load in to the type checker. Note that definition file syntax is currently unstable and may change at any time
    definitionFiles = {},
    ---@type string[] @A list of paths to documentation files which provide documentation support to the definition files provided
    documentationFiles = {},
    --- Load in and automatically update Roblox type definitions for the type checker
    roblox = false,
  },

  fflags = {
    --- Enable all (boolean) Luau FFlags by default. These flags can later be overriden by `server.fflags.override` and `server.fflags.sync`
    enableByDefault = false,
    --- Sync currently enabled FFlags with Roblox's published FFlags. This currently only syncs FFlags which begin with "Luau"
    sync = true,
    ---@type table<string, "True"|"False"|number> @Override FFlags passed to Luau
    override = {},
  },
}

local M = {
  ---@type LuauLspConfig
  values = vim.deepcopy(DEFAULTS),
}

---@param config LuauLspConfig
function M.setup(config)
  M.values = vim.tbl_deep_extend("force", M.values, config)
end

---@return LuauLspConfig
function M.get()
  return M.values
end

return M
