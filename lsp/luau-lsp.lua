local config = require "luau-lsp.config"

local function rojo_project(bufnr)
  return vim.fs.root(bufnr, function(name)
    return name:match ".+%.project%.json$"
  end)
end

---@type vim.lsp.Config
return {
  filetypes = { "luau" },
  root_markers = { { "selene.toml", "stylua.toml" }, { ".git" } },
  root_dir = function(bufnr, on_dir)
    on_dir(rojo_project(bufnr))
  end,
  settings = {
    ["luau-lsp"] = {
      platform = {
        type = config.get().platform.type,
      },
      sourcemap = {
        enabled = config.get().sourcemap.enabled,
        autogenerate = config.get().sourcemap.autogenerate,
        sourcemapFile = config.get().sourcemap.sourcemap_file,
      },
    },
  },
  commands = {
    ["luau-lsp.rename"] = function(command, ctx)
      local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
      local uri, position = unpack(assert(command.arguments))

      assert(vim.lsp.util.show_document({
        uri = uri,
        range = {
          start = position,
          ["end"] = position,
        },
      }, client.offset_encoding))

      vim.lsp.buf.rename(nil, {
        filter = function(candidate)
          return candidate.id == client.id
        end,
      })
    end,
  },

  -- HACK: pull diagnostics do not update affected files, so force push based diagnostics
  -- https://github.com/JohnnyMorganz/luau-lsp/issues/541
  capabilities = { textDocument = { diagnostic = vim.NIL } },
  on_init = function(client)
    client.server_capabilities.diagnosticProvider = nil
  end,
}
