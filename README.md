# luau-lsp.nvim

A [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp/) extension to improve your experience in Neovim.

https://github.com/lopi-py/luau-lsp.nvim/assets/70210066/4fa6d3b1-44fe-414f-96ff-b2d58e840080

## Requirements

* Neovim 0.11.2+
* [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

Use your favorite plugin manager to install luau-lsp.nvim

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

> [!CAUTION]
> `lspconfig.luau_lsp.setup` and `vim.lsp.enable("luau_lsp")` should **NOT** be called, as it might cause conflicts with this plugin

```lua
require("luau-lsp").setup {
  ...
}
```

### Using mason-lspconfig.nvim

[mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) will try to automatically enable `luau_lsp`. To prevent this, make sure to exclude it:

```lua
require("mason-lspconfig").setup {
  automatic_enable = {
    exclude = { "luau_lsp" },
  },
}
```

## Roblox

Roblox types are downloaded from the luau-lsp page and passed to the language server.

```lua
require("luau-lsp").setup {
  platform = {
    type = "roblox",
  },
  types = {
    roblox_security_level = "PluginSecurity",
  },
}
```

### Rojo sourcemap

Sourcemap generation is done by running `rojo sourcemap --watch --output sourcemap.json default.project.json`.

```lua
require("luau-lsp").setup {
  sourcemap = {
    enabled = true,
    autogenerate = true, -- automatic generation when the server is initialized
    rojo_project_file = "default.project.json",
    sourcemap_file = "sourcemap.json",
  },
}
```

#### Custom generator

You can specify a custom generator command using `sourcemap.generator_cmd`. Note that `sourcemap.rojo_project_file` and `sourcemap.sourcemap_file` will be ignored. This option is recommended for [per-project configuration](#project-configuration).

```lua
require("luau-lsp").setup {
  sourcemap = {
    -- based on https://argon.wiki/docs/commands/cli#sourcemap
    generator_cmd = { "argon", "sourcemap", "--watch", "--non-scripts" },
  },
}
```

`:LuauLsp regenerate_sourcemap` is provided to restart sourcemap generation.

### Companion plugin

You can install the companion plugin [here](https://create.roblox.com/store/asset/10913122509/Luau-Language-Server-Companion).

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
    definition_files = {
      ["@foo"] = "path/to/definitions/file",
      bar = "https://some.url/file.d.luau", -- @ will be added internally
    },
    documentation_files = { "path/to/documentation/file" },
  },
}
```

## Luau FFLags

```lua
require("luau-lsp").setup {
  fflags = {
    enable_new_solver = true, -- enables the fflags required for luau's new type solver
    sync = true, -- sync currently enabled fflags with roblox's published fflags
    override = { -- override fflags passed to luau 
      LuauTableTypeMaximumStringifierLength = "100",
    },
  },
}
```

## Bytecode generation

`:LuauLsp bytecode` and `:LuauLsp compiler_remarks` open a new window and show the current Luau file bytecode and compiler remarks. It will automatically update when you change or edit the file. Close with `q`.

https://github.com/lopi-py/luau-lsp.nvim/assets/70210066/f9d45153-47f0-4565-a2ed-3769153732a0

## Server configuration

See `:help vim.lsp.config`

```lua
vim.lsp.config("luau-lsp", {
  settings = {
    ["luau-lsp"] = {
      completion = {
        imports = {
          enabled = true, -- enable auto imports
        },
      },
    },
  },
})
```

For full **server** options check the [luau-lsp schema](https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json)

## Project configuration

Add the following to your `.nvim.lua`

```lua
require("luau-lsp").config {
  ...
}
```

For more info about `.nvim.lua`, check `:help 'exrc'`

## Configuration

<details>

<summary>Defaults</summary>

```lua
---@alias luau-lsp.PlatformType "standard" | "roblox"
---@alias luau-lsp.RobloxSecurityLevel "None" | "LocalUserSecurity" | "PluginSecurity" | "RobloxScriptSecurity"

---@class luau-lsp.Config : {}
local defaults = {
  platform = {
    ---@type luau-lsp.PlatformType
    type = "roblox",
  },
  sourcemap = {
    enabled = true,
    autogenerate = true,
    rojo_path = "rojo",
    rojo_project_file = "default.project.json",
    include_non_scripts = true,
    sourcemap_file = "sourcemap.json",
    ---@type string[]?
    generator_cmd = nil,
  },
  types = {
    ---@type table<string, string>
    definition_files = {},
    ---@type string[]
    documentation_files = {},
    ---@type luau-lsp.RobloxSecurityLevel
    roblox_security_level = "PluginSecurity",
  },
  fflags = {
    enable_by_default = false,
    enable_new_solver = false,
    sync = true,
    ---@type table<string, string>
    override = {},
  },
  plugin = {
    enabled = false,
    port = 3667,
  },
  server = {
    path = "luau-lsp",
  },
}
```

</details>

## Troubleshooting

### Health checks

To verify the setup, run `:checkhealth luau-lsp`

### Log file

To open the `luau-lsp.nvim` log file, run `:LuauLsp log`

## FAQ

### Why doesn't the server detect changes in the sourcemap?

Make sure to enable the file watcher capability

```lua
vim.lsp.config("*", {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
})
```

### How to set the platform automatically?

```lua
local function rojo_project()
  return vim.fs.root(0, function(name)
    return name:match ".+%.project%.json$"
  end)
end

require("luau-lsp").setup {
  platform = {
    type = rojo_project() and "roblox" or "standard",
  },
}
```

### How to use luau-lsp in a Roblox codebase using the .lua extension?

```lua
local function rojo_project()
  return vim.fs.root(0, function(name)
    return name:match ".+%.project%.json$"
  end)
end

if rojo_project() then
  vim.filetype.add {
    extension = {
      lua = function(path)
        return path:match "%.nvim%.lua$" and "lua" or "luau"
      end,
    },
  }
end
```

### How to setup jsonls to recognize Rojo project files?

```lua
local schemas = {
  {
    name = "default.project.json",
    description = "JSON schema for Rojo project files",
    fileMatch = { "*.project.json" },
    url = "https://raw.githubusercontent.com/rojo-rbx/vscode-rojo/master/schemas/project.template.schema.json",
  },
}

vim.lsp.config("jsonls", {
  settings = {
    json = {
      -- without SchemaStore.nvim
      schemas = schemas,

      -- or if using SchemaStore.nvim
      -- schemas = require("schemastore").json.schemas { extra = schemas },

      validate = {
        enabled = true
      },
    },
  },
})
```
