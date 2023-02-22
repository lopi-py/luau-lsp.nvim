---@class LuauLspConfig
local DEFAULTS = {
  ---@type string[] @Root files to find workspace folder
  root_files = {
    "*.project.json",
    ".luaurc",
    "aftman.toml",
    "selene.toml",
    "stylua.toml",
    ".git",
  },

  sourcemap = {
    --- Whether Rojo sourcemap parsing is enabled
    enabled = false,
    --- Automatically run the `rojo sourcemap` command to regenerate sourcemaps on changes
    autogenerate = false,
    --- Path to the Rojo executable. If not provided, attempts to run `rojo` in the workspace directory, so it must be available on the PATH
    rojo_path = "rojo",
    --- The name of the Rojo project file to generate a sourcemap for. Only applies if `sourcemap.autogenerate` is enabled
    rojo_project_file = "default.project.json",
    --- Include non-script instances in the generated sourcemap
    include_non_scripts = true,
  },

  server = {
    types = {
      ---@type string[] @A list of paths to definition files to load in to the type checker. Note that definition file syntax is currently unstable and may change at any time
      definition_files = {},
      ---@type string[] @A list of paths to documentation files which provide documentation support to the definition files provided
      documentation_files = {},
      --- Load in and automatically update Roblox type definitions for the type checker
      roblox = false,
    },

    fflags = {
      --- Enable all (boolean) Luau FFlags by default. These flags can later be overriden by `server.fflags.override` and `server.fflags.sync`
      enable_by_default = false,
      --- Sync currently enabled FFlags with Roblox's published FFlags. This currently only syncs FFlags which begin with "Luau"
      sync = true,
      ---@type table<string, "True"|"False"|number> @Override FFlags passed to Luau
      overrides = {},
    },

    ---@type table<string, any> @Server settings, see [luau lsp settings](https://github.com/JohnnyMorganz/luau-lsp/blob/main/editors/code/package.json)
    settings = {},
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
