local M = {}

---@class LuauLspConfig
local defaults = {
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

---@type LuauLspConfig
M.options = nil

---@param options? LuauLspConfig
function M.setup(options)
  M.options = vim.tbl_deep_extend("force", defaults, options or {})

  require("luau-lsp.sourcemap").setup()
  require("luau-lsp.server").setup()
end

---@return LuauLspConfig
function M.get()
  return M.options
end

return M
