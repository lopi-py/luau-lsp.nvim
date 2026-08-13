local async = require "luau-lsp.async"
local wsl = require "luau-lsp.roblox.wsl"

---@class luau-lsp.roblox.ScriptSyncNode
---@field FilePaths? string[]
---@field Children? luau-lsp.roblox.ScriptSyncNode[]

local M = {}

local cwd = assert(vim.uv.cwd())

---@return string[]?
local function file_scanner()
  if vim.fn.executable "fd" == 1 then
    return {
      "fd",
      "--absolute-path",
      "--no-ignore",
      "--color=never",
      "--type",
      "f",
      "-e",
      "lua",
      "-e",
      "luau",
      "--",
      ".",
      cwd,
    }
  end

  if vim.fn.executable "rg" == 1 then
    return {
      "rg",
      "--files",
      "--no-ignore",
      "--color=never",
      "-g",
      "*.lua",
      "-g",
      "*.luau",
      "-g",
      "!.*",
      "-g",
      "!**/.*",
      "--",
      cwd,
    }
  end
end

---@param callback fun(err: string?, files: string[]?)
M.find_script_files = async.wrap(function(callback)
  local cmd = file_scanner()
  if not cmd then
    callback "Native Script Sync file discovery requires 'fd' or 'rg'"
    return
  end

  local ok, err = pcall(vim.system, cmd, { text = true }, function(result)
    local stdout = result.stdout --[[@as string]]
    local stderr = result.stderr --[[@as string]]

    if stderr ~= "" then
      callback(string.format("Failed to scan Luau files with '%s': %s", cmd[1], vim.trim(stderr)))
      return
    end

    local paths = vim.split(stdout, "\n", { trimempty = true })
    callback(nil, vim.tbl_map(wsl.to_windows_path, paths))
  end)

  if not ok then
    callback(string.format("Failed to start command '%s': %s", cmd[1], err))
  end
end)

---@param node luau-lsp.roblox.ScriptSyncNode
local function normalize_node(node)
  local paths = node.FilePaths
  if paths then
    for i = 1, #paths do
      paths[i] = wsl.to_wsl_path(paths[i])
    end
  end

  local children = node.Children
  if children then
    for i = 1, #children do
      normalize_node(children[i])
    end
  end
end

---@param tree luau-lsp.roblox.ScriptSyncNode
function M.normalize_file_paths(tree)
  if not wsl.is_wsl then
    return
  end
  normalize_node(tree)
end

return M
