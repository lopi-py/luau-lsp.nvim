local M = {}

---@class LuauLspConfig
local defaults = {
  sourcemap = {
    enabled = true,
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
    root_pattern = function(path)
      return vim.find({
        ".git",
        ".luaurc",
        "selene.toml",
        "stylua.toml",
        "aftman.toml",
        "wally.toml",
        "*.project.json",
      }, { path = path })
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
