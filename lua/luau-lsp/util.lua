local M = {}

M.is_windows = vim.uv.os_uname().sysname == "Windows_NT"

---@param path string
---@return boolean
function M.is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file" or false
end

---@param path string
---@return boolean
function M.is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "directory" or false
end

---@vararg string
---@return string
function M.joinpath(...)
  return table.concat({ ... }, M.is_windows and "\\" or "/")
end

---@vararg string
---@return string
function M.storage_file(...)
  local args = { ... }
  local path = M.joinpath(vim.fn.stdpath "data", "luau-lsp", unpack(args, 1, #args - 1))
  if not M.is_dir(path) then
    vim.fn.mkdir(path, "p")
  end
  return M.joinpath(path, args[#args])
end

---@param bufnr? integer
---@return vim.lsp.Client?
function M.get_client(bufnr)
  return vim.lsp.get_clients({ name = "luau-lsp", bufnr = bufnr })[1]
end

---@param url string
---@param opts? { output: string? }
---@param on_response? fun(err?: string, res?: { body: string }))
function M.request(url, opts, on_response)
  opts = opts or {}

  local cmd = { "curl", "-f", "-L", "-s", "-S", url }
  if opts.output then
    vim.list_extend(cmd, { "-o", opts.output, "--create-dirs" })
  end

  vim.system(cmd, {}, function(result)
    local msg = "Request failed with exit code %d"
    local err = result.code ~= 0
        and ((result.stderr ~= "" and result.stderr) or string.format(msg, result.code))
      or nil
    local res = result.code == 0 and { body = result.stdout } or nil

    if on_response then
      vim.schedule_wrap(on_response)(err, res)
    end
  end)
end

return M
