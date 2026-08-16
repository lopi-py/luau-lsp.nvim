# luau-lsp.nvim

A [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp/) extension to improve your experience in Neovim.

https://github.com/lopi-py/luau-lsp.nvim/assets/70210066/4fa6d3b1-44fe-414f-96ff-b2d58e840080

## Requirements

* Neovim 0.12+
* [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp/) 1.60.0+ available on `$PATH`, or configured with `server.path`
* [Rojo](https://rojo.space/) 7.3.0+ for default sourcemap generation

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

## Standard Luau

Built-in Luau API documentation is downloaded automatically for standard projects.

```lua
require("luau-lsp").setup {
  platform = {
    type = "standard",
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

Sourcemap generation is done by running `rojo sourcemap --watch --output sourcemap.json default.project.json --include-non-scripts` by default.

```lua
require("luau-lsp").setup {
  sourcemap = {
    enabled = true,
    autogenerate = true, -- automatic generation when the server is initialized
    rojo_path = "rojo",
    rojo_project_file = "default.project.json",
    include_non_scripts = true,
    sourcemap_file = "sourcemap.json",
  },
}
```

#### Custom generator

You can specify a custom generator command using `sourcemap.generator_cmd`. The command is run exactly as provided, so the Rojo-specific options do not affect it. The generator must write the file configured by `sourcemap.sourcemap_file`, which the language server watches for changes. This option is recommended for [per-project configuration](#project-configuration).

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

Native Script Sync file discovery requires [`fd`](https://github.com/sharkdp/fd) or [`ripgrep`](https://github.com/BurntSushi/ripgrep) (`rg`) to be available on `$PATH`.

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

Remote definition and documentation files are cached for one day to avoid re-downloading them on every start. Run `:LuauLsp refresh_types` to ignore the cache and fetch fresh copies on demand.

## Luau FFLags

```lua
require("luau-lsp").setup {
  fflags = {
    enable_by_default = false, -- start luau-lsp with --no-flags-enabled
    enable_new_solver = true, -- enables the fflags required for luau's new type solver
    sync = true, -- sync currently enabled fflags with roblox's published fflags
    override = { -- override fflags passed to luau
      LuauTableTypeMaximumStringifierLength = 100,
    },
  },
}
```

## Bytecode generation

`:LuauLsp bytecode`, `:LuauLsp compiler_remarks`, and `:LuauLsp codegen` open a new window and show compiler output for the current Luau file. CodeGen prompts for an assembly target after selecting the optimization level. The view automatically updates when you change or edit the file. Close it with `q`.

https://github.com/lopi-py/luau-lsp.nvim/assets/70210066/f9d45153-47f0-4565-a2ed-3769153732a0

## Server configuration

See `:help vim.lsp.config`

```lua
vim.lsp.config("luau-lsp", {
  settings = {
    ["luau-lsp"] = {
      completion = {
        fillCallArguments = false, -- disable arguments snippets when completing a function call
      },
    },
  },
})
```

For full **server** options check the [luau-lsp schema](https://github.com/folke/neoconf.nvim/blob/main/schemas/luau_lsp.json)

### Plugin server options

```lua
require("luau-lsp").setup {
  server = {
    path = "path/to/luau-lsp", -- path to the luau-lsp server binary
    base_luaurc = "path/to/.luaurc", -- path to a `.luaurc` file which acts as the default baseline luau config
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

<details>

<summary>Defaults</summary>

See [`lua/luau-lsp/config.lua`](lua/luau-lsp/config.lua) for option types and validation.

```lua
local defaults = {
  platform = {
    type = "roblox",
  },
  sourcemap = {
    enabled = true,
    autogenerate = true,
    rojo_path = "rojo",
    rojo_project_file = "default.project.json",
    include_non_scripts = true,
    sourcemap_file = "sourcemap.json",
    generator_cmd = nil,
  },
  types = {
    definition_files = {},
    documentation_files = {},
    roblox_security_level = "PluginSecurity",
  },
  fflags = {
    enable_by_default = false,
    enable_new_solver = false,
    sync = true,
    override = {},
  },
  plugin = {
    enabled = false,
    port = 3667,
  },
  server = {
    path = "luau-lsp",
    base_luaurc = nil,
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
        enabled = true,
      },
    },
  },
})
```
