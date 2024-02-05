local compat = require "luau-lsp.compat"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"

local M = {}
M._method = "luau-lsp/bytecode"
M._optlevel = 0

local function is_attached(bufnr)
  local clients = compat.get_clients { name = "luau_lsp", bufnr = bufnr }
  return #clients > 0
end

local function get_optimization_level(callback)
  local optimization_levels = { "02", "01", "None" }
  local optimization_levels_map = {
    ["None"] = 0,
    ["01"] = 1,
    ["02"] = 2,
  }

  vim.ui.select(optimization_levels, {
    prompt = "Select optimization level",
  }, function(choice)
    if choice and optimization_levels_map[choice] then
      callback(optimization_levels_map[choice])
    end
  end)
end

local function create_bytecode_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[bufnr].filetype = "luau"
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false

  vim.api.nvim_buf_set_var(bufnr, "luau-bytecode", true)

  vim.keymap.set("n", "q", M.close, {
    silent = true,
    buffer = bufnr,
    desc = "Close the window",
  })

  local id = vim.api.nvim_create_autocmd(
    { "BufEnter", "BufNewFile", "InsertLeave", "TextChanged" },
    {
      pattern = vim.tbl_map(function(ft)
        return "*." .. ft
      end, config.get().server.filetypes or { "luau" }),

      callback = function(ev)
        M.update_buffer(ev.buf)
      end,
    }
  )

  vim.api.nvim_create_autocmd("BufWipeout", {
    once = true,
    buffer = bufnr,
    callback = function()
      vim.api.nvim_del_autocmd(id)
    end,
  })

  return bufnr
end

local function create_bytecode_window()
  local winnr = vim.api.nvim_get_current_win()
  local bufnr = create_bytecode_buffer()
  local splitright = vim.o.splitright

  vim.o.splitright = true
  vim.cmd "vsplit"
  vim.o.splitright = splitright

  vim.api.nvim_win_set_var(vim.api.nvim_get_current_win(), "luau-bytecode", true)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_set_current_win(winnr)
end

local function get_bytecode_buffer()
  for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
    local success, value = pcall(vim.api.nvim_buf_get_var, bufnr, "luau-bytecode")
    if success and value then
      return bufnr
    end
  end
end

local function get_bytecode_window()
  for _, winnr in pairs(vim.api.nvim_list_wins()) do
    local success, value = pcall(vim.api.nvim_win_get_var, winnr, "luau-bytecode")
    if success and value then
      return winnr
    end
  end
end

local function set_bytecode_text(text)
  local bufnr = get_bytecode_buffer()
  if not bufnr then
    return
  end

  vim.api.nvim_win_call(get_bytecode_window(), function()
    local view = vim.fn.winsaveview() --[[@as vim.fn.winsaveview.ret]]
    local lines = vim.split(text, "\n")

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false
    vim.fn.winrestview(view)
  end)
end

local function show_bytecode_info(method, scheme, filename)
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_attached(bufnr) then
    return
  end

  get_optimization_level(function(optlevel)
    M._optlevel = optlevel
    M._method = method

    if not get_bytecode_window() then
      create_bytecode_window()
    end

    if not get_bytecode_buffer() then
      vim.api.nvim_win_set_buf(get_bytecode_window(), create_bytecode_buffer())
    end

    vim.api.nvim_buf_set_name(
      get_bytecode_buffer(),
      string.format("%s://bytecode/%s.luau", scheme, filename)
    )

    M.update_buffer(bufnr)
  end)
end

function M.update_buffer(bufnr)
  if not is_attached(bufnr) then
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    optimizationLevel = M._optlevel,
  }

  vim.lsp.buf_request(bufnr, M._method, params, function(err, result)
    if err then
      log.error(err.message)
      return
    end

    set_bytecode_text(result:gsub("[\n]+$", ""))
  end)
end

function M.close()
  local bufnr = get_bytecode_buffer()
  if bufnr then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end

  local winnr = get_bytecode_window()
  if winnr then
    vim.api.nvim_win_close(winnr, true)
  end
end

function M.bytecode()
  show_bytecode_info("luau-lsp/bytecode", "luau-bytecode", "bytecode")
end

function M.compiler_remarks()
  show_bytecode_info("luau-lsp/compilerRemarks", "luau-remarks", "compiler-remarks")
end

return M
