local util = require "luau-lsp.util"

local function create_luau_buffer()
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.bo[bufnr].filetype = "luau"

  vim.api.nvim_set_current_buf(bufnr)

  -- HACK: the lsp won't be attached, we need to wait a bit
  vim.wait(0)

  return bufnr
end

local function await_client()
  vim.wait(5000, function()
    return util.get_client() ~= nil
  end)

  local client = util.get_client()
  assert.is_truthy(client)
  return client
end

describe("luau-lsp server", function()
  vim.opt.runtimepath:append(vim.uv.cwd())

  require("luau-lsp.server").setup()
  require("luau-lsp.config").config {
    platform = {
      type = "standard",
    },
  }

  after_each(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      vim.api.nvim_buf_delete(bufnr, {})
    end
  end)

  it("should attach to a luau buffer", function()
    local bufnr = create_luau_buffer()
    local client = await_client()
    assert.same({ bufnr }, vim.lsp.get_buffers_by_client_id(client.id))
  end)
end)
