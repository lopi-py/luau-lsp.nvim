local config = require "luau-lsp.config"
local file_source = require "luau-lsp.server.file_source"
local test_util = require "spec.test_util"
local types = require "luau-lsp.server.types"

local it_async = test_util.it_async

describe("server.types.resolve", function()
  before_each(function()
    config.config {
      platform = {
        type = "standard",
      },
    }

    stub(file_source, "resolve", function(source)
      return source
    end)
  end)

  after_each(function()
    config._reset()
    file_source.resolve:revert()
  end)

  it_async("resolves named definition files", function()
    config.config {
      types = {
        definition_files = {
          test = "/path/to/test.d.luau",
          ["@roblox"] = "/path/to/roblox.d.luau",
        },
      },
    }

    local definitions = types.resolve()

    assert.same({
      ["@test"] = "/path/to/test.d.luau",
      ["@roblox"] = "/path/to/roblox.d.luau",
    }, definitions)
  end)

  it_async("derives definition names from a file list", function()
    config.config {
      types = {
        definition_files = {
          "/path/to/test.d.luau",
        },
      },
    }

    local definitions = types.resolve()

    assert.same({
      ["@test"] = "/path/to/test.d.luau",
    }, definitions)
  end)

  it_async("resolves documentation files", function()
    config.config {
      types = {
        documentation_files = {
          "/path/to/docs.json",
        },
      },
    }

    local _, documentation = types.resolve()

    assert.is_true(vim.tbl_contains(documentation, "/path/to/docs.json"))
  end)
end)
