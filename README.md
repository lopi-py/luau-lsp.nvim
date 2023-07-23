# Luau LSP
Luau lsp extension with fully luau support!

## Usage
You should use `require("luau-lsp").setup {}` instead of `lspconfig.luau_lsp.setup {}`
<details>
<summary>mason-lspconfig.nvim</summary>

```lua
require("mason-lspconfig").setup_handlers {
  ["luau_lsp"] = function()
    require("luau-lsp").setup { ... }
  end,
}
```
</details>

## Treesitter
Note that nvim-treesitter has its own luau parser but causes some [conflicts](https://github.com/polychromatist/tree-sitter-luau#note-on-the-neovim-case), so the following line is required
```lua
require("luau-lsp").treesitter() -- required

-- treesitter configs here
```
`:TSInstall luau`

## Roblox
This plugin also supports roblox environment:
```lua
require("luau-lsp").setup {
  sourcemap = {
    enable = true, -- enable sourcemap generation
    autogenerate = true, -- auto generate sourcemap when saving/deleting buffers
  },
  types = {
    roblox = true, -- enable roblox api
  },
}
```

## Adding definition files
```lua
require("luau-lsp").setup {
  types = {
    definitionFiles = { "testez.d.luau", "path/to/definition/file" },
    documentationFiles = { "path/to/documentation/file" },
  },
}
```

## Override Luau FFLags
```lua
require("luau-lsp").setup {
  fflags = {
    override = {
      LuauTarjanChildLimit = 0,
    },
  },
}
```

## Server Settings
```lua
require("luau-lsp").setup {
  -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
  completion = {
    imports = {
      enabled = true,
    },
  },
}
```

## Configuration
```lua
local config = {
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

  -- server specific options
  -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
  -- e.g. completion.imports.enabled:
  completion = {
    imports = {
      enabled = true,
    },
  },
}
```

### Credits
* [luau language server](https://github.com/JohnnyMorganz/luau-lsp/)
* [tree sitter luau](https://github.com/polychromatist/tree-sitter-luau)

### TODO
* Add some way to set local configs, might be useful for `types` or `sourcemap.rojoProjectFile`
* Add an action to sync queries and parser's revision
