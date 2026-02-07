-- converts paths between WSL (/mnt/c/...) and Windows (C:\...) formats.
-- the Roblox Studio plugin sends Windows paths in sourcemap trees, and neovim
-- running under WSL needs them as /mnt/ paths (and vice versa for responses).
-- uses FFI for to_wsl_path because it is called per-file in large sourcemaps.

---@diagnostic disable: inject-field

local ffi = require "ffi"

local PATH_CACHE_LIMIT = 50000

local M = {}

local cwd = assert(vim.uv.cwd())
local is_wsl = vim.fn.has "wsl" == 1 and vim.startswith(cwd, "/mnt/")

---@type table<string, string?>
local windows_path_cache = {}
local windows_path_cache_size = 0

---@type table<string, string?>
local wsl_path_cache = {}
local wsl_path_cache_size = 0

local wsl_buf_size = 4096
local wsl_buf = ffi.new("uint8_t[?]", wsl_buf_size)

---@param path string
---@return string
local function to_windows_path(path)
  local cached = windows_path_cache[path]
  if cached then
    return cached
  end

  local drive, rest = path:match "^/mnt/(%a)/(.*)"
  if not drive or not rest then
    return path
  end

  local converted = drive:upper() .. ":\\" .. rest:gsub("/", "\\")

  if windows_path_cache_size >= PATH_CACHE_LIMIT then
    windows_path_cache = {}
    windows_path_cache_size = 0
  end

  windows_path_cache[path] = converted
  windows_path_cache_size = windows_path_cache_size + 1

  return converted
end

---@param path string
---@return string
local function to_wsl_path(path)
  local cached = wsl_path_cache[path]
  if cached then
    return cached
  end

  local len = #path
  local b1, b2 = path:byte(1, 2)
  -- b2 == 58 is ':', b1 must be A-Z or a-z (drive letter check: "C:\...")
  if b2 ~= 58 or not ((b1 >= 65 and b1 <= 90) or (b1 >= 97 and b1 <= 122)) then
    return path
  end

  local new_len = len + 4
  if new_len > wsl_buf_size then
    wsl_buf_size = new_len * 2
    wsl_buf = ffi.new("uint8_t[?]", wsl_buf_size)
  end

  -- write "/mnt/" prefix, then drive letter (ensure lowercase), then "/"
  wsl_buf[0] = 47 -- /
  wsl_buf[1] = 109 -- m
  wsl_buf[2] = 110 -- n
  wsl_buf[3] = 116 -- t
  wsl_buf[4] = 47 -- /
  wsl_buf[5] = b1 >= 65 and b1 <= 90 and b1 + 32 or b1 -- uppercase A-Z -> lowercase
  wsl_buf[6] = 47 -- /

  -- copy everything after "C:\" and replace backslashes (92) with forward slashes (47)
  ffi.copy(wsl_buf + 7, path:sub(4), len - 3)
  for j = 7, new_len - 1 do
    if wsl_buf[j] == 92 then
      wsl_buf[j] = 47
    end
  end

  local converted = ffi.string(wsl_buf, new_len)

  if wsl_path_cache_size >= PATH_CACHE_LIMIT then
    wsl_path_cache = {}
    wsl_path_cache_size = 0
  end

  wsl_path_cache[path] = converted
  wsl_path_cache_size = wsl_path_cache_size + 1

  return converted
end

---@return string[]
function M.find_luau_files()
  local files = vim.fn.glob(cwd .. "/**/*.{lua,luau}", false, true)
  for i, file in ipairs(files) do
    files[i] = is_wsl and to_windows_path(file) or file
  end
  return files
end

---@param node table
local function normalize_node(node)
  local paths = node.FilePaths
  if paths then
    for i = 1, #paths do
      paths[i] = to_wsl_path(paths[i])
    end
  end

  local children = node.Children
  if children then
    for i = 1, #children do
      normalize_node(children[i])
    end
  end
end

---@param tree table
function M.normalize_file_paths(tree)
  if not is_wsl then
    return
  end

  normalize_node(tree)
end

return M
