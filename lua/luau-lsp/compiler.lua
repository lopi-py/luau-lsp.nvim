local async = require "luau-lsp.async"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local UPDATE_EVENTS = { "BufEnter", "BufNewFile", "InsertLeave", "TextChanged" }

local M = {}

local view_bufnr = -1
local view_winnr = -1
local current_method = "luau-lsp/bytecode"
local current_optimization_level = 0
---@type string?
local current_codegen_target

---@async
---@return integer?
local function select_optimization_level()
  ---@diagnostic disable-next-line: redundant-return-value
  return async.await(vim.ui.select, { 2, 1, 0 }, {
    prompt = "Select optimization level",
    format_item = function(item)
      return item > 0 and string.format("%.2d", item) or "None"
    end,
  })
end

---@async
---@return string?
local function select_codegen_target()
  ---@diagnostic disable-next-line: redundant-return-value
  return async.await(vim.ui.select, {
    "host",
    "a64",
    "a64_nofeatures",
    "x64_windows",
    "x64_systemv",
  }, {
    prompt = "Select CodeGen target",
  })
end

local function is_view_valid()
  return vim.api.nvim_win_is_valid(view_winnr) and vim.api.nvim_buf_is_valid(view_bufnr)
end

local function close_view()
  if vim.api.nvim_win_is_valid(view_winnr) then
    vim.api.nvim_win_close(view_winnr, true)
  end
  if vim.api.nvim_buf_is_valid(view_bufnr) then
    vim.api.nvim_buf_delete(view_bufnr, { force = true })
  end
end

---@param bufnr integer
local function update_view(bufnr)
  local client = util.get_client(bufnr)
  if not client then
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    optimizationLevel = current_optimization_level,
    codeGenTarget = current_codegen_target,
  }

  ---@cast current_method vim.lsp.protocol.Method.ClientToServer.Request
  client:request(current_method, params, function(err, result)
    if err then
      log.error(err.message)
      return
    end

    if not is_view_valid() then
      return
    end

    local lines = vim.split(result, "\n", { trimempty = true })
    vim.bo[view_bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(view_bufnr, 0, -1, false, lines)
    vim.bo[view_bufnr].modifiable = false
  end, bufnr)
end

---@param bufname string
local function create_view(bufname)
  vim.cmd "belowright vnew"

  view_bufnr = vim.api.nvim_get_current_buf()
  view_winnr = vim.api.nvim_get_current_win()

  vim.wo[view_winnr].winfixbuf = true
  vim.bo[view_bufnr].buflisted = false
  vim.bo[view_bufnr].buftype = "nofile"
  vim.bo[view_bufnr].bufhidden = "wipe"
  vim.bo[view_bufnr].swapfile = false
  vim.bo[view_bufnr].modifiable = false

  vim.api.nvim_buf_set_name(view_bufnr, bufname)

  if not pcall(vim.treesitter.start, view_bufnr, "luau") then
    vim.bo[view_bufnr].syntax = "luau"
  end

  vim.keymap.set("n", "q", close_view, {
    buffer = view_bufnr,
    desc = "Close the window",
  })

  local group = vim.api.nvim_create_augroup("luau-lsp.compiler.output", {})

  vim.api.nvim_create_autocmd(UPDATE_EVENTS, {
    group = group,
    callback = function(event)
      update_view(event.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufUnload", {
    group = group,
    buffer = view_bufnr,
    callback = function()
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })

  -- triggers BufEnter and updates the view
  vim.cmd.wincmd "p"
end

---@param method string
---@param bufname string
local show_compiler_output = async.void(function(method, bufname)
  local bufnr = vim.api.nvim_get_current_buf()
  if not util.get_client(bufnr) then
    return
  end

  local optimization_level = select_optimization_level()
  if not optimization_level then
    return
  end

  local codegen_target
  if method == "luau-lsp/codeGen" then
    codegen_target = select_codegen_target()
    if not codegen_target then
      return
    end
  end

  current_method = method
  current_optimization_level = optimization_level
  current_codegen_target = codegen_target

  close_view()
  create_view(bufname)
end)

function M.show_bytecode()
  show_compiler_output("luau-lsp/bytecode", "luau-lsp://compiler/bytecode.luau")
end

function M.show_remarks()
  show_compiler_output("luau-lsp/compilerRemarks", "luau-lsp://compiler/remarks.luau")
end

function M.show_codegen()
  show_compiler_output("luau-lsp/codeGen", "luau-lsp://compiler/codegen.luau")
end

return M
