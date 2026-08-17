local View = require "luau-lsp.view"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local UPDATE_EVENTS = { "BufEnter", "BufNewFile", "InsertLeave", "TextChanged" }

local M = {}

local view = View.new()
local update_id = 0

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
  }

  client:request("luau-lsp/debug/viewInternalSource", params, function(err, result)
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

function M.show()
  local bufnr = vim.api.nvim_get_current_buf()
  if not util.get_client(bufnr) then
    return
  end

  view:open {
    name = "luau-lsp://internal-source/source.luau",
    augroup = "luau-lsp.internal-source",
  }

  view:autocmd(UPDATE_EVENTS, {
    callback = function(event)
      update_view(event.buf)
    end,
  })

  update_view(bufnr)
end

return M
