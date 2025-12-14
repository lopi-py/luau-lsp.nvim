local Context = require "luau-lsp.context"
local config = require "luau-lsp.config"
local server = require "luau-lsp.server"

describe("server.build_cmd", function()
  local original_config

  before_each(function()
    original_config = vim.deepcopy(config.get())
  end)

  after_each(function()
    config.config(original_config)
  end)

  it("should include server path as first argument", function()
    config.config { server = { path = "/usr/bin/luau-lsp" } }
    local ctx = Context.new()
    local cmd = server.build_cmd(ctx)

    assert.equal("/usr/bin/luau-lsp", cmd[1])
    assert.equal("lsp", cmd[2])
  end)

  it("should add definition files to command", function()
    local ctx = Context.new()
    ctx:add_definitions("test", "./spec/roblox-project/test.d.luau")
    ctx:add_definitions("@roblox", "./spec/roblox-project/roblox.d.luau")

    local cmd = server.build_cmd(ctx)

    local has_test = false
    local has_roblox = false
    for _, arg in ipairs(cmd) do
      if arg:match "^%-%-definitions:@test=" then
        has_test = true
      end
      if arg:match "^%-%-definitions:@roblox=" then
        has_roblox = true
      end
    end

    assert.is_true(has_test)
    assert.is_true(has_roblox)
  end)

  it("should add documentation files to command", function()
    local ctx = Context.new()
    ctx:add_documentation "./spec/roblox-project/docs.json"

    local cmd = server.build_cmd(ctx)

    local has_docs = false
    for _, arg in ipairs(cmd) do
      if arg:match "^%-%-docs=" then
        has_docs = true
      end
    end

    assert.is_true(has_docs)
  end)

  it("should include --no-flags-enabled when fflags.enable_by_default is false", function()
    config.config { fflags = { enable_by_default = false } }
    local ctx = Context.new()
    local cmd = server.build_cmd(ctx)

    assert.is_true(vim.tbl_contains(cmd, "--no-flags-enabled"))
  end)

  it("should not include --no-flags-enabled when fflags.enable_by_default is true", function()
    config.config { fflags = { enable_by_default = true } }
    local ctx = Context.new()
    local cmd = server.build_cmd(ctx)

    assert.is_false(vim.tbl_contains(cmd, "--no-flags-enabled"))
  end)

  it("should add base .luaurc to command", function()
    config.config { server = { base_luaurc = "./spec/roblox-project/.luaurc" } }
    local ctx = Context.new()
    local cmd = server.build_cmd(ctx)

    local has_base_luaurc = false
    for _, arg in ipairs(cmd) do
      if arg:match "^%-%-base%-luaurc=" then
        has_base_luaurc = true
      end
    end

    assert.is_true(has_base_luaurc)
  end)
end)
