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
        capabilities = vim.lsp.protocol.make_client_capabilities(), -- just an example
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
Note that nvim-treesitter has its own luau parser but causes some [conflicts](https://github.com/polychromatist/tree-sitter-luau#note-on-the-neovim-case), so you can opt in for the custom parser:
```lua
require("luau-lsp").treesitter() -- optional

-- treesitter configs here
require("nvim-treesitter.configs").setup {
  ...
}
```
`:TSInstall luau`
It is important that you call `require("luau-lsp").treesitter()` BEFORE your actual treesitter config, you need to reinstall the parser every time you switch between luau parsers.
If you want to only use the default parser, just ignore this step.

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

Select rojo project for sourcemap generation with
`:RojoSourcemap`

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
All the previous settings are plugin-specific (should be specified under `setup`, also note that all keys there should be in `lower_case`), server-specific settings should be specified under `server.settings["luau-lsp"]` and in `camelCase`:
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

## Bytecode generation
`:LuauBytecode` and `:LuauCompilerRemarks` open a new window and show the current Luau file bytecode and compiler remarks. It will automatically update if you change the file or edit it. Close with `q`.

### Configuration
`luau-lsp.nvim` comes with the following defaults
```lua
require("luau-lsp").setup {
  sourcemap = {
    enabled = true,
    rojo_path = "rojo",
    include_non_scripts = true,
    ---@type fun():string?
    select_project_file = nil,
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
    root_dir = function(path)
      local util = require "lspconfig.util"
      return util.find_git_ancestor(path)
        or util.root_pattern(
          ".luaurc",
          "selene.toml",
          "stylua.toml",
          "aftman.toml",
          "wally.toml",
          "mantle.yml",
          "*.project.json"
        )(path)
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
- [x] ~~Add some way to set local configs, might be useful for `types` or `sourcemap.rojo_project_file`~~ you probably want `:help 'exrc'`
- [ ] Add a github action to sync queries and parser's revision
