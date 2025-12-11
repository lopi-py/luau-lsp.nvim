# Changelog

## [Unreleased]

### Added

- Add `:LuauLsp redownload_api` command to force refresh cached files
- Cache remote definition and documentation downloads for one day to avoid unnecessary re-downloads
- Option `server.base_luaurc` to specify a base `.luaurc` file for the server
- Option `sourcemap.generator_cmd` to specify a custom sourcemap generator command
- Option `server.path` to allow the use of locally installed luau-lsp binaries
- Asynchronous GZip decompression to improve performance when receiving large data models
- Option `fflags.enable_new_solver` to enable the flags required for Luau's new type solver
- Option `sourcemap.sourcemap_file` to specify a different name to use for the sourcemap

### Changed

- `types.definition_files` format changed from `string[]` to table `["@name"] = "path/url"`, allowing both file paths and URLs
- Deprecated `server.*` options except the new `server.path`
- Bytecode and compiler remarks window now use treesitter
- Upgraded the required version of `luau-lsp` to `1.57.0`

### Deprecated

- Using `types.definition_files` as an list is deprecated in favor of a table with named keys

### Removed

- Argument {file} for `:LuauLsp regenerate_sourcemap` command
- Dropped support for Neovim 0.9 and 0.10
- Deprecated function `require("luau-lsp").aliases()` as now luau-lsp has built-in support
- Deprecated option `types.roblox`
- Deprecated commands starting with `Luau*`

### Fixed

- Handle large http payloads properly
- Kill rojo sourcemap process on exit

## [1.6.0] - 2024-08-29

### Added

- `require("luau-lsp").aliases()` to read and return aliases from `.luaurc`

### Fixed

- Error loading the server when root directory is not found
- Definition files that depend on Roblox types will now load properly
- Merge internal modified capabilities with the default client capabilities if not specified in the server config
- Sourcemap generation and studio server will only start if the configured platform is `roblox`

## [1.5.0] - 2024-08-01

### Added

- Error handling for curl when there is no internet connection
- GZip decompression support for the studio plugin server ([#23](https://github.com/lopi-py/luau-lsp.nvim/pull/23))
- Support for tilde (`~`) expansion in definition and documentation files
- Health checks (`:checkhealth luau-lsp`)
- `:LuauLsp` single command
- Changelog file

### Changed

- Rojo project files (`*.project.json`) have more priority when finding the root directory

### Deprecated

- Commands starting with `:Luau` in favor of `:LuauLsp` single command

### Removed

- `treesitter()` function

## [1.4.0] - 2024-04-07

### Added

- Support for luau-lsp studio companion plugin ([#17](https://github.com/lopi-py/luau-lsp.nvim/pull/17))

### Changed

- Log messages will now display the plugin name even without a notification plugin

### Removed

- Custom treesitter parser in favor of the built-in one

### Fixed

- Neovim 0.9 compatibility
- Improved bytecode performance on large files

## [1.3.0] - 2024-01-06

### Added

- `sourcemap.autogenerate` and `sourcemap.rojo_project_file` options
- `types.roblox_security_level` option
- Support for `:help 'exrc'` neovim option

### Changed

- Renamed command `:RojoSourcemap` to `:LuauRegenerateSourcemap`

### Removed

- `sourcemap.select_rojo_project` in favor of `sourcemap.rojo_project_file`

### Fixed

- Sourcemap notifications in non rojo projects
- Bytecode buffer issues

## [1.2.0] - 2023-12-31

### Added

- `:LuauBytecode` and `:LuauCompilerRemarks` commands

### Fixed

- Roblox types download errors on Windows

## [1.1.0] - 2023-11-26

### Added

- `sourcemap.select_project_file` option

### Changed

- Custom treesitter is optional now

### Removed

- `sourcemap.rojo_project_file` option

## [1.0.1] - 2023-09-08

### Fixed

- lspconfig error when using manager

## [1.0.0] - 2023-09-08

### Changed

- Plugin specific and server specific configurations split up

## [0.1.0] - 2023-08-17

Initial release
