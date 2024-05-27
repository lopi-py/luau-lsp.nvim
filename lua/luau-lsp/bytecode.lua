local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local UPDATE_EVENTS = { "BufEnter", "BufNewFile", "InsertLeave", "TextChanged" }

local M = {}

local current_method = "luau-lsp/bytecode"
local current_optlevel = 0

local bytecode_bufnr = -1
local bytecode_winnr = -1

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

local function is_view_valid()
  return vim.api.nvim_win_is_valid(bytecode_winnr) and vim.api.nvim_buf_is_valid(bytecode_bufnr)
end

local function close_view()
  if vim.api.nvim_win_is_valid(bytecode_winnr) then
    vim.api.nvim_win_close(bytecode_winnr, true)
  end

  if vim.api.nvim_buf_is_valid(bytecode_bufnr) then
    vim.api.nvim_buf_delete(bytecode_bufnr, { force = true })
  end
end

local function create_view()
  vim.cmd "belowright vsplit +enew"

  local augroup = vim.api.nvim_create_augroup("luau-lsp.bytecode", {})

  bytecode_bufnr = vim.api.nvim_get_current_buf()
  bytecode_winnr = vim.api.nvim_get_current_win()

  vim.bo[bytecode_bufnr].buflisted = false
  vim.bo[bytecode_bufnr].buftype = "nofile"
  vim.bo[bytecode_bufnr].bufhidden = "wipe"
  vim.bo[bytecode_bufnr].swapfile = false
  vim.bo[bytecode_bufnr].modifiable = false

  -- treesitter is too slow to parse luau bytecode (freezes neovim), we could wait for
  -- https://github.com/neovim/neovim/pull/22420
  vim.bo[bytecode_bufnr].syntax = "luau"

  vim.keymap.set("n", "q", close_view, {
    silent = true,
    buffer = bytecode_bufnr,
    desc = "Close the window",
  })

  vim.api.nvim_create_autocmd(UPDATE_EVENTS, {
    group = augroup,
    callback = function(event)
      local bufnr = event.buf
      if vim.bo[bufnr].filetype == "luau" then
        M.update_buffer(bufnr)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = augroup,
    buffer = bytecode_bufnr,
    callback = function()
      vim.api.nvim_del_augroup_by_id(augroup)
    end,
  })

  vim.cmd.wincmd "p"
end

local function render_view_text(text)
  if not is_view_valid() then
    return
  end

  local lines = vim.split(text, "\n")

  vim.bo[bytecode_bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bytecode_bufnr, 0, -1, false, lines)
  vim.bo[bytecode_bufnr].modifiable = false
end

local function show_bytecode_info(method, filename)
  local bufnr = vim.api.nvim_get_current_buf()
  if not util.get_client(bufnr) then
    return
  end

  get_optimization_level(function(optlevel)
    current_optlevel = optlevel
    current_method = method

    if is_view_valid() then
      M.update_buffer(bufnr)
    else
      close_view()
      create_view()
    end

    vim.api.nvim_buf_set_name(bytecode_bufnr, string.format("%s.luau", filename))
  end)
end

function M.update_buffer(bufnr)
  local client = util.get_client(bufnr)
  if not client then
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    optimizationLevel = current_optlevel,
  }

  client.request(current_method, params, function(err, result)
    if err then
      log.error(err.message)
      return
    end

    render_view_text(result:gsub("[\n]+$", ""))
  end, bufnr)
end

function M.bytecode()
  show_bytecode_info("luau-lsp/bytecode", "bytecode")
end

function M.compiler_remarks()
  show_bytecode_info("luau-lsp/compilerRemarks", "compiler-remarks")
end

return M
