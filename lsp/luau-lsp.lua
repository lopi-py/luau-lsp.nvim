local config = require "luau-lsp.config"

local function rojo_project(bufnr)
  return vim.fs.root(bufnr, function(name)
    return name:match ".+%.project%.json$"
  end)
end

return {
  filetypes = { "luau" },
  root_markers = { ".git", "selene.toml", "stylua.toml" },
  root_dir = function(bufnr, on_dir)
    on_dir(rojo_project(bufnr))
  end,
  capabilities = { textDocument = { diagnostic = vim.NIL } },
  settings = {
    ["luau-lsp"] = {
      platform = {
        type = config.get().platform.type,
      },
      sourcemap = {
        enabled = config.get().sourcemap.enabled,
        sourcemapFile = config.get().sourcemap.sourcemap_file,
      },
    },
  },
  on_init = function(client)
    client.server_capabilities.diagnosticProvider = nil
  end,
}
