# Luau LSP
Luau lsp extension with fully luau support!

## Usage
You should use `require("luau-lsp.server").setup {}` instead of `lspconfig.luau_lsp.setup {}`
<details>
<summary>mason-lspconfig.nvim</summary>

```lua
require("mason-lspconfig").setup_handlers {
  luau_lsp = function()
    -- use this function like require("lspconfig").luau_lsp.setup { ... }
    require("luau-lsp.server").setup {
      filetypes = { "lua", "luau" }, -- default is { "luau" }
      settings = {
        ["luau-lsp"] = {
          ...,
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
require("luau-lsp.server").setup {
  settings = {
    ["luau-lsp"] = {
      sourcemap = {
        enable = true, -- enable sourcemap generation
        autogenerate = true, -- auto generate sourcemap with rojo's sourcemap watcher
      },
      types = {
        roblox = true, -- enable roblox api
      },
    },
  },
}
```

## Adding definition files
```lua
require("luau-lsp.server").setup {
  settings = {
    ["luau-lsp"] = {
      types = {
        definitionFiles = { "testez.d.luau", "path/to/definition/file" },
        documentationFiles = { "path/to/documentation/file" },
      },
    },
  },
}
```

## Override Luau FFLags
```lua
require("luau-lsp.server").setup {
  settings = {
    ["luau-lsp"] = {
      fflags = {
        override = {
          LuauTarjanChildLimit = 0,
        },
      },
    },
  },
}
```

## Auto Imports
```lua
require("luau-lsp.server").setup {
  settings = {
    ["luau-lsp"] = {
      completion = {
        imports = {
          enabled = true,
        },
      },
    },
  },
}
```

### See [this schema](https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json) for full `luau-lsp.` options

### Credits
* [luau language server](https://github.com/JohnnyMorganz/luau-lsp/)
* [tree sitter luau](https://github.com/polychromatist/tree-sitter-luau)

### TODO
* Add some way to set local configs, might be useful for `luau-lsp.types` or `luau-lsp.sourcemap.rojoProjectFile`
* Add a github action to sync queries and parser's revision
