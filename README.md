# luau-lsp.nvim

A [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp/) extension to improve your experience in neovim.

https://github.com/lopi-py/luau-lsp.nvim/assets/70210066/4fa6d3b1-44fe-414f-96ff-b2d58e840080

## Requirements

* Neovim 0.9+ (nightly is recommended)
* [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

Use your favourite plugin manager to install luau-lsp.nvim

<details>

<summary>lazy.nvim</summary>

```lua
{
  "lopi-py/luau-lsp.nvim",
  opts = {
    ...
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
}
```

</details>

<details>

<summary>packer.nvim</summary>

```lua
use {
  "lopi-py/luau-lsp.nvim",
  config = function()
    require("luau-lsp").setup {
      ...
    }
  end,
  requires = {
    "nvim-lua/plenary.nvim",
  },
}
```

</details>

## Quick start

```lua
require("luau-lsp").setup {
  ...
}
```

<details>

<summary>mason-lspconfig.nvim</summary>

```lua
require("mason-lspconfig").setup_handlers {
  luau_lsp = function()
    require("luau-lsp").setup {
      ...
    }
  end,
}
```

</details>

> [!CAUTION]
> lspconfig's setup should **NOT** be called as the plugin does it internally
> ```lua
> require("lspconfig").luau_lsp.setup { ... }
> ```
> Use `luau-lsp.nvim`'s setup instead
> ```lua
> require("luau-lsp").setup { ... }
> ```

## Roblox

Roblox types are downloaded from the luau-lsp repo and passed to the language server.

```lua
require("luau-lsp").setup {
  types = {
    roblox = true,
    roblox_security_level = "PluginSecurity",
  },
}
```

### Rojo sourcemap

Sourcemap generation is done by running `rojo sourcemap --watch default.project.json --output sourcemap.json`.

```lua
require("luau-lsp").setup {
  sourcemap = {
    enabled = true,
    autogenerate = true, -- automatic generation when the server is attached
    rojo_project_file = "default.project.json",
  },
}
```

`:LuauRegenerateSourcemap {file}` is provided to start sourcemap generation with the project file passed as argument (optional).

### Companion plugin

You can install the companion plugin [here](https://create.roblox.com/store/asset/10913122509/Luau-Language-Server-Companion?externalSource=www).

```lua
require("luau-lsp").setup {
  plugin = {
    enabled = true,
    port = 3667,
  },
}
```

## Definition files

```lua
require("luau-lsp").setup {
  types = {
    definition_files = { "path/to/definitions/file" },
    documentation_files = { "path/to/documentation/file" },
  },
}
```

## Luau FFLags

```lua
require("luau-lsp").setup {
  fflags = {
    sync = true, -- sync currently enabled fflags with roblox's published fflags
    override = {
      LuauTarjanChildLimit = 0,
    },
  },
}
```

## Bytecode generation

`:LuauBytecode` and `:LuauCompilerRemarks` open a new window and show the current Luau file bytecode and compiler remarks. It will automatically update if you change the file or edit it. Close with `q`.

https://github.com/lopi-py/luau-lsp.nvim/assets/70210066/f9d45153-47f0-4565-a2ed-3769153732a0

## Server settings

```lua
require("luau-lsp").setup {
  server = {
    settings = {
      -- https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
      ["luau-lsp"] = {
        completion = {
          imports = {
            enabled = true, -- enable auto imports
          },
        },
      },
    },
  },
}
```

## Project configuration

Add the following to your `.nvim.lua`

```lua
require("luau-lsp").config {
  ...
}
```

For more info about `.nvim.lua`, check `:help 'exrc'`

## Configuration

`luau-lsp.nvim` comes with the following defaults:

```lua
---@class LuauLspConfig
local defaults = {
  sourcemap = {
    enabled = true,
    autogenerate = true,
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
    roblox_security_level = "PluginSecurity",
  },
  fflags = {
    enable_by_default = false,
    sync = true,
    ---@type table<string, "True"|"False"|number>
    override = {},
  },
  plugin = {
    enabled = false,
    port = 3667,
  },
  ---@type table<string, any>
  server = {
    cmd = { "luau-lsp", "lsp" },
    root_dir = function(path)
      local compat = require "luau-lsp.compat"
      return vim.fs.dirname(vim.fs.find(function(name)
        return name:match ".*%.project.json$"
          or compat.list_contains({
            ".git",
            ".luaurc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
          }, name)
      end, {
        upward = true,
        path = path,
      })[1])
    end,
    -- see https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json
    settings = {},
  },
}
```

## FAQ

### Why doesn't the luau filetype detection work?

Don't lazy load the plugin if you are on neovim v0.9.x

### Why doesn't the autocompletion detect changes in the sourcemap?

Make sure to pass the client capabilities in the server settings

```lua
local capabilities = vim.lsp.procotol.make_client_capabilities()

require("luau-lsp").setup {
  server = {
    capabilities = capabilities,
  },
}
```

If you are using [nvim-cmp](https://github.com/hrsh7th/nvim-cmp), check [this guide](https://github.com/hrsh7th/cmp-nvim-lsp?tab=readme-ov-file#setup)

### What is the error "server not yet received configuration for diagnostics"?

Neovim is asking for diagnostics to the server but it hasn't loaded the configuration yet, you can just ignore this error. This is monkey patched but may not work on v0.9.x

### Why aren't my luau files highlighted?

Try installing the `luau` treesitter parser (`:TSInstall luau`)

### How to use luau-lsp on a lua codebase without messing with lua_ls?

Enable `:help 'exrc'` and add the following to your `.nvim.lua`:

```lua
vim.filetype.add {
  extension = {
    lua = function(path)
      return path:match ".nvim.lua$" and "lua" or "luau"
    end,
  },
}
```
