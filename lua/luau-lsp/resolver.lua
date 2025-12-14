local async = require "luau-lsp.async"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local CACHE_TTL = 24 * 60 * 60

local M = {}

---@param path string
---@param callback fun(is_valid: boolean)
local is_cache_valid = async.wrap(function(path, callback)
  vim.uv.fs_stat(path, function(_, stat)
    if stat and stat.type == "file" then
      callback(os.time() - stat.mtime.sec < CACHE_TTL)
    else
      callback(false)
    end
  end)
end)

---@async
---@param source string
---@param output string
---@param opts { force?: boolean }
---@return string?
local function resolve_remote_file(source, output, opts)
  if not opts.force and is_cache_valid(output) then
    return output
  end

  local err = async.await(util.request, source, { output = output })
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
---@param opts? { force: boolean? }
---@return string?
function M.resolve_file(source, output, opts)
  opts = opts or {}

  if source:find "^https?://" then
    return resolve_remote_file(source, output, opts)
  else
    return vim.fs.normalize(source)
  end
end

return M
