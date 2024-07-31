-- Support for non-nightly neovim versions, once the nightly version is released, the compat
-- for it will be removed from here after a while.

local M = {}

---@type uv
M.uv = vim.loop or vim.uv

---@diagnostic disable-next-line: deprecated
M.get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients

---@param client vim.lsp.Client
function M.get_client_settings(client)
  return client.settings or client.config.settings
end

---@param t table
---@param value any
---@return boolean
function M.list_contains(t, value)
  if vim.list_contains then
    return vim.list_contains(t, value)
  end

  for _, v in ipairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

---@param t table
---@return Iter
function M.iter(t)
  if vim.iter then
    return vim.iter(t)
  end

  local iter = {}
  iter.t = vim.deepcopy(t)

  function iter:filter(f)
    local result = {}

    for key, value in pairs(self.t) do
      if f(key, value) then
        result[key] = value
      end
    end

    self.t = result
    return self
  end

  function iter:map(f)
    local result = {}

    for key, value in pairs(self.t) do
      key, value = f(key, value)
      result[key] = value
    end

    self.t = result
    return self
  end

  function iter:each(f)
    for key, value in pairs(self.t) do
      f(key, value)
    end

    return self
  end

  return iter
end

return M
