local M = {}

---@generic R
---@param func async fun(): R ...
---@param on_finish? fun(err: string?, ...: R ...)
function M.run(func, on_finish)
  local thread = coroutine.create(func)
  local on_finish_or_error = on_finish or function(err)
    error(err, 0)
  end

  local function step(...)
    local ret = vim.F.pack_len(coroutine.resume(thread, ...))
    local stat = ret[1]

    if not stat then
      on_finish_or_error(ret[2])
    elseif coroutine.status(thread) == "dead" then
      if on_finish then
        on_finish(nil, unpack(ret, 2, ret.n))
      end
    else
      local ok, err = pcall(ret[2], step)
      if not ok then
        on_finish_or_error(err)
      end
    end
  end

  step()
end

---@generic R
---@param func async fun(...: R ...)
---@return fun(...: R ...)
function M.void(func)
  return function(...)
    local args = vim.F.pack_len(...)
    M.run(function()
      func(vim.F.unpack_len(args))
    end)
  end
end

---@async
---@overload fun<R>(func: fun(callback: fun(...: R ...))): R ...
---@generic T, R
---@param func fun(...: T ..., callback: fun(...: R ...))
---@param ... T ...
---@return R ...
function M.await(func, ...)
  local args = vim.F.pack_len(...)
  args.n = args.n + 1

  return coroutine.yield(function(callback)
    args[args.n] = callback
    ---@diagnostic disable-next-line: missing-parameter
    func(vim.F.unpack_len(args))
  end)
end

---@overload fun<R>(func: fun(callback: fun(...: R ...))): async fun(): R ...
---@generic T, R
---@param func fun(...: T ..., callback: fun(...: R ...))
---@return async fun(...: T ...): R ...
function M.wrap(func)
  ---@async
  return function(...)
    return M.await(func, ...)
  end
end

---@async
---@param funcs async fun()[]
function M.join(funcs)
  if #funcs == 0 then
    return
  end

  local err = M.await(function(callback)
    local remaining = #funcs
    local finished = false

    local function on_finish(child_err)
      if finished then
        return
      end

      if child_err then
        finished = true
        callback(child_err)
        return
      end

      remaining = remaining - 1
      if remaining == 0 then
        finished = true
        callback()
      end
    end

    for _, func in ipairs(funcs) do
      M.run(func, on_finish)
    end
  end)

  if err then
    error(err, 0)
  end
end

return M
