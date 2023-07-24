---@class LuauLspConfig
local DEFAULTS = {
  sourcemap = {
    enabled = true,
    autogenerate = true,
    rojoPath = nil,
    rojoProjectFile = "default.project.json",
    includeNonScripts = true,
  },
  types = {
    definitionFiles = {},
    documentationFiles = {},
    roblox = true,
  },
  fflags = {
    enableByDefault = false,
    sync = true,
    override = {},
  },
}

local M = {
  ---@type LuauLspConfig
  values = vim.deepcopy(DEFAULTS),
}

---@param config LuauLspConfig
function M.setup(config)
  M.values = vim.tbl_deep_extend("force", M.values, config)
end

---@return LuauLspConfig
function M.get()
  return M.values
end

return M
