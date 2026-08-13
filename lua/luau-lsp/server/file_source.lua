local async = require "luau-lsp.async"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

---@class luau-lsp.server.file_source.FileSource
---@field source string
---@field output string

local CACHE_TTL_SECONDS = 24 * 60 * 60

local M = {}

---@param path string
---@param callback fun(result: boolean)
local is_cache_valid = async.wrap(function(path, callback)
  vim.uv.fs_stat(path, function(_, stat)
    if stat and stat.type == "file" then
      callback(os.time() - stat.mtime.sec < CACHE_TTL_SECONDS)
    else
      callback(false)
    end
  end)
end)

---@param source string
---@param output string
---@param callback fun(err: string?)
local download_file = async.wrap(function(source, output, callback)
  vim.schedule(function()
    vim.fn.mkdir(vim.fs.dirname(output), "p")
    vim.net.request(source, { outpath = output }, callback)
  end)
end)

---@async
---@param source string
---@param output string
---@param opts { force?: boolean }
---@return string?
local function resolve_remote(source, output, opts)
  if not opts.force and is_cache_valid(output) then
    return output
  end

  local err = download_file(source, output)
  if not err then
    return output
  elseif util.is_file(output) then
    log.warn("Failed to download file from '%s', local version found: %s", source, err)
    return output
  end
  log.error("Failed to download file from '%s': %s", source, err)
end

---@async
---@param source string
---@param output string
---@param opts? { force?: boolean }
---@return string?
function M.resolve(source, output, opts)
  opts = opts or {}
  if source:match "^https?://" then
    return resolve_remote(source, output, opts)
  end

  return vim.fs.normalize(source)
end

return M
