local PATH_CACHE_LIMIT = 50000

local M = {}

local cwd = assert(vim.uv.cwd())

M.is_wsl = vim.fn.has "wsl" == 1 and vim.startswith(cwd, "/mnt/")

---@type table<string, string?>
local windows_path_cache = {}
local windows_path_cache_size = 0

---@type table<string, string?>
local wsl_path_cache = {}
local wsl_path_cache_size = 0

---@param byte integer?
---@return boolean
local function is_drive_letter(byte)
  return byte ~= nil and ((byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122))
end

---@param path string
---@return boolean
local function is_wsl_drive_path(path)
  return vim.startswith(path, "/mnt/") and path:byte(7) == 47 and is_drive_letter(path:byte(6))
end

---@param path string
---@return boolean
local function is_windows_path(path)
  return path:byte(2) == 58 and path:byte(3) == 92 and is_drive_letter(path:byte(1))
end

---@param path string
---@return string
function M.to_windows_path(path)
  if not M.is_wsl then
    return path
  end

  if windows_path_cache[path] then
    return windows_path_cache[path]
  end

  if not is_wsl_drive_path(path) then
    return path
  end

  if windows_path_cache_size >= PATH_CACHE_LIMIT then
    windows_path_cache = {}
    windows_path_cache_size = 0
  end

  local drive = path:byte(6)
  windows_path_cache[path] = string.char(drive >= 97 and drive - 32 or drive)
    .. ":\\"
    .. path:sub(8):gsub("/", "\\")
  windows_path_cache_size = windows_path_cache_size + 1

  return windows_path_cache[path]
end

---@param path string
---@return string
function M.to_wsl_path(path)
  if not M.is_wsl then
    return path
  end

  if wsl_path_cache[path] then
    return wsl_path_cache[path]
  end

  if not is_windows_path(path) then
    return path
  end

  if wsl_path_cache_size >= PATH_CACHE_LIMIT then
    wsl_path_cache = {}
    wsl_path_cache_size = 0
  end

  local drive = path:byte(1)
  wsl_path_cache[path] = "/mnt/"
    .. string.char(drive <= 90 and drive + 32 or drive)
    .. "/"
    .. path:sub(4):gsub("\\", "/")
  wsl_path_cache_size = wsl_path_cache_size + 1

  return wsl_path_cache[path]
end

return M
