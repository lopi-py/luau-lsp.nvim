# Luau LSP
Luau lsp extension with fully luau support!

![](https://i.gyazo.com/c91af237f64ca4c81f4732334050dd0e.gif)

## Usage
```lua
require("luau-lsp").setup { ... }
```
<details>
<summary>mason-lspconfig.nvim</summary>

```lua
require("mason-lspconfig").setup_handlers {
  luau_lsp = function()
    require("luau-lsp").setup {
      server = { -- options passed to `require("lspconfig").luau_lsp.setup`
        filetypes = { "lua", "luau" }, -- default is { "luau" }
        settings = {
          ["luau-lsp"] = {
            ...,
          },
        },
      },
    }
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
    definition_files = { "testez.d.luau", "path/to/definition/file" },
    documentation_files = { "path/to/documentation/file" },
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

## Server-specific settings
All the previous settings are plugin-specific (should be specified under `setup`, also note that all keys here should be in `lower_case`), server-specific settings should be specified under `server.settings["luau-lsp"]`:
```lua
require("luau-lsp").setup {
  server = {
    settings = {
      ["luau-lsp"] = {
        -- enable auto imports
        completion = {
          imports = {
            enabled = true,
          },
        },
      },
    },
  },
}
```

### Configuration
`luau-lsp.nvim` comes with the following defaults
```lua
require("luau-lsp").setup {
  sourcemap = {
    enabled = true,
    rojo_path = "rojo",
    rojo_project_file = "default.project.json",
    include_non_scripts = true,
  },
  types = {
    ---@type string[]
    definition_files = {},
    ---@type string[]
    documentation_files = {},
    roblox = true,
  },
  fflags = {
    enable_by_default = false,
    sync = true,
    ---@type table<string, "True"|"False"|number>
    override = {},
  },
  ---@type table<string, any>
  server = {
    cmd = { "luau-lsp", "lsp" },
    root_pattern = function(path)
      return vim.find({
        ".git",
        ".luaurc",
        "selene.toml",
        "stylua.toml",
        "aftman.toml",
        "wally.toml",
        "*.project.json",
      }, { path = path })
    end,
    -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
    settings = {},
  },
}
```

### Credits
* [luau language server](https://github.com/JohnnyMorganz/luau-lsp/)
* [tree sitter luau](https://github.com/polychromatist/tree-sitter-luau)

### TODO
* Add a github action to sync queries and parser's revision
