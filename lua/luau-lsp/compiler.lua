local View = require "luau-lsp.view"
local async = require "luau-lsp.async"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local UPDATE_EVENTS = { "BufEnter", "BufNewFile", "InsertLeave", "TextChanged" }

local M = {}

local view = View.new()
local update_id = 0
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

---@param bufnr integer
local function update_view(bufnr)
  update_id = update_id + 1
  local expected_update_id = update_id

  local client = util.get_client(bufnr)
  if not client then
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    optimizationLevel = current_optimization_level,
    codeGenTarget = current_codegen_target,
  }

  client:request(current_method, params, function(err, result)
    if update_id ~= expected_update_id or not view:is_open() then
      return
    end

    if err then
      log.error(err.message)
      return
    end

    view:set_content(result)
  end, bufnr)
end

---@param method string
---@param filename string
local show_compiler_output = async.void(function(method, filename)
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

  view:open {
    name = filename,
    augroup = "luau-lsp.compiler.output",
  }

  view:autocmd(UPDATE_EVENTS, {
    callback = function(event)
      update_view(event.buf)
    end,
  })

  update_view(bufnr)
end)

function M.show_bytecode()
  show_compiler_output("luau-lsp/bytecode", "luau-lsp://compiler/bytecode.asm")
end

function M.show_remarks()
  show_compiler_output("luau-lsp/compilerRemarks", "luau-lsp://compiler/remarks.luau")
end

function M.show_codegen()
  show_compiler_output("luau-lsp/codeGen", "luau-lsp://compiler/codegen.asm")
end

return M
