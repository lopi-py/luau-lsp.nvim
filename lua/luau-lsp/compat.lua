-- Support for non-nightly neovim versions, once the nightly version is released, the compat
-- for it will be removed from here after a while.

local M = {}

function M.iter(t)
  if vim.iter then
    return vim.iter(t)
  end

  local iter = {
    t = vim.deepcopy(t),
  }

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
