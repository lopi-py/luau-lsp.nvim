local config = require "luau-lsp.config"
local server = require "luau-lsp.server"

local buffers = {}

local function create_luau_buffer()
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.bo[bufnr].filetype = "luau"

  server.start(bufnr)
  table.insert(buffers, bufnr)

  vim.api.nvim_set_current_buf(bufnr)

  return bufnr
end

local function wait_for_client()
  vim.wait(5000, function()
    local clients = vim.lsp.get_clients { name = "luau-lsp" }
    return clients[1] ~= nil
  end)

  local clients = vim.lsp.get_clients { name = "luau-lsp" }
  assert.same(1, #clients)

  return clients[1]
end

describe("luau-lsp server", function()
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function() end

  after_each(function()
    local client = wait_for_client()
    client.stop(true)
    vim.wait(100)

    for _, bufnr in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, {})
      end
    end
  end)

  it("should attach a client to a luau buffer", function()
    local bufnr = create_luau_buffer()
    local client = wait_for_client()
    assert.same({ bufnr }, vim.lsp.get_buffers_by_client_id(client.id))
  end)

  it("should resue the same client for multiple buffers", function()
    local first = create_luau_buffer()
    local second = create_luau_buffer()
    local third = create_luau_buffer()

    server.start(first)
    server.start(second)
    server.start(third)

    local client = wait_for_client()
    assert.same({ first, second, third }, vim.lsp.get_buffers_by_client_id(client.id))
  end)

  it("should handle roblox configuration", function()
    config.config {
      platform = {
        type = "standard",
      },
      sourcemap = {
        enabled = false,
      },
    }

    local notify = stub(vim, "notify")
    local bufnr = create_luau_buffer()
    local client = wait_for_client()

    assert.stub(notify).called(0)
    assert.same({ vim.fn.exepath "luau-lsp", "lsp", "--no-flags-enabled" }, client.config.cmd)

    client.stop(true)
    vim.wait(100)

    config.config {
      platform = {
        type = "roblox",
      },
      sourcemap = {
        enabled = true,
      },
    }

    server.start(bufnr)
    client = wait_for_client()

    assert
      .stub(notify).was
      .called_with("[luau-lsp.nvim] Unable to find project file 'default.project.json'", vim.log.levels.ERROR)
    assert.match("globalTypes.PluginSecurity.d.luau", client.config.cmd[3])
    assert.match("api%-docs.json", client.config.cmd[4])
  end)

  it("should respect user settings", function()
    config.config {
      server = {
        settings = {
          ["luau-lsp"] = {
            testSetting = {
              testField = "testing",
            },
          },
        },
      },
    }

    create_luau_buffer()
    local client = wait_for_client()

    assert.same({
      ["luau-lsp"] = {
        platform = {
          type = "roblox",
        },
        sourcemap = {
          enabled = true,
        },
        testSetting = {
          testField = "testing",
        },
      },
    }, client.settings)
  end)
end)
