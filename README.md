# Luau LSP

A [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp/) extension to improve your experience in neovim.

# Installation

## [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "lopi-py/luau-lsp.nvim",
  ft = { "luau" }
  opts = {
    ...
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  }
}
```

## [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "lopi-py/luau-lsp.nvim",
  ft = { "luau" },
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

# Setup

## [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)

```lua
require("mason-lspconfig").setup_handlers {
  luau_lsp = function()
    require("luau-lsp").setup {
      ...
    }
  end,
}
```

# Roblox

Roblox types and sourcemap generation are supported:

```lua
require("luau-lsp").setup {
  sourcemap = {
    enable = true,
    autogenerate = true, -- automatic generation when the server is attached
    rojo_project_file = "default.project.json"
  },
  types = {
    roblox = true,
    roblox_security_level = "PluginSecurity",
  },
}
```

`:LuauRegenerateSourcemap` is provided to start sourcemap generation with the project file passed as argument or the one configured in `sourcemap.rojo_project_file`, will stop the current job and start a new one if required.

# Definition files

```lua
require("luau-lsp").setup {
  types = {
    definition_files = { "path/to/definitions/file" },
    documentation_files = { "path/to/documentation/file" },
  },
}
```

# Luau FFLags

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

# Bytecode generation

`:LuauBytecode` and `:LuauCompilerRemarks` open a new window and show the current Luau file bytecode and compiler remarks. It will automatically update if you change the file or edit it. Close with `q`.

# Server settings

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

# Treesitter

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

# Project configuration

It is allowed to config a project with `:h 'exrc'`

```lua
vim.o.exrc = true
```

```lua
-- .nvim.lua
require("luau-lsp").config {
  ...
}
```

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
  ---@type table<string, any>
  server = {
    cmd = { "luau-lsp", "lsp" },
    root_dir = function(path)
      local util = require "luau-lsp.util"
      return vim.fs.dirname(vim.fs.find(function(name)
        return name:match ".*%.project.json$"
          or util.list_contains({
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
