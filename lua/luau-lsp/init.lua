local util = require "luau-lsp.util"

local M = {}

function M.treesitter()
  local success, parsers = pcall(require, "nvim-treesitter.parsers")
  if not success then
    vim.notify("nvim-treesitter not found", vim.log.levels.ERROR, { title = "luau lsp" })
    return
  end

  parsers.get_parser_configs().luau = {
    install_info = {
      url = "https://github.com/polychromatist/tree-sitter-luau",
      files = { "src/parser.c", "src/scanner.c" },
      -- HACK: manually set the revision since treesitter has its own parser & revision for luau
      revision = util.parser_revision(),
    },
  }

  -- HACK: override the given query just in case of treesitter's queries are found first
  local function override_query(query_type)
    vim.treesitter.query.set("luau", query_type, util.get_query(query_type))
  end

  override_query "folds"
  override_query "highlights"
  override_query "indents"
  override_query "injections"
  override_query "locals"
end

return M
