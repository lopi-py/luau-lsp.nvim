local M = {}

---@param fn async fun(): ...: any
---@param on_finish? fun(err: string?, ...: any)
function M.run(fn, on_finish)
  local thread = coroutine.create(fn)
  local on_finish_or_error = on_finish or error

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

---@param fn async fun(...: any)
---@return fun(...: any)
function M.void(fn)
  return function(...)
    local args = vim.F.pack_len(...)
    M.run(function()
      fn(vim.F.unpack_len(args))
    end)
  end
end

---@async
---@param fn fun(...: any, cb: fun(...: any))
---@param ... any
---@return any ...
function M.await(fn, ...)
  local args = vim.F.pack_len(...)
  return coroutine.yield(function(callback)
    args.n = args.n + 1
    args[args.n] = callback
    fn(vim.F.unpack_len(args))
  end)
end

---@param fn fun(...: any, cb: fun(...: any))
---@return async fun(...: any): ...: any
function M.wrap(fn)
  return function(...)
    return M.await(fn, ...)
  end
end

---@async
---@param fns (async fun())[]
function M.join(fns)
  local len = #fns
  if len == 0 then
    return
  end

  M.await(function(on_finish)
    local done = 0
    for _, fn in ipairs(fns) do
      M.run(fn, function()
        done = done + 1
        if done == len then
          on_finish()
        end
      end)
    end
  end)
end

return M
