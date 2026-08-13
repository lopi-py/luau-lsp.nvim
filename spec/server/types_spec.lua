local config = require "luau-lsp.config"
local file_source = require "luau-lsp.server.file_source"
local test_util = require "spec.test_util"
local types = require "luau-lsp.server.types"

local it_async = test_util.it_async

describe("server.types.resolve", function()
  local original_definition_files
  local original_documentation_files
  local original_platform_type

  before_each(function()
    original_definition_files = vim.deepcopy(config.get().types.definition_files)
    original_documentation_files = vim.deepcopy(config.get().types.documentation_files)
    original_platform_type = config.get().platform.type
    stub(file_source, "resolve", function(source)
      return source
    end)

    config.get().platform.type = "standard"
  end)

  after_each(function()
    file_source.resolve:revert()
    config.get().types.definition_files = original_definition_files
    config.get().types.documentation_files = original_documentation_files
    config.get().platform.type = original_platform_type
  end)

  it_async("resolves named definition files", function()
    config.get().types.definition_files = {
      test = "/path/to/test.d.luau",
      ["@roblox"] = "/path/to/roblox.d.luau",
    }

    local definitions = types.resolve()

    assert.same({
      ["@test"] = "/path/to/test.d.luau",
      ["@roblox"] = "/path/to/roblox.d.luau",
    }, definitions)
  end)

  it_async("derives definition names from a file list", function()
    config.get().types.definition_files = {
      "/path/to/test.d.luau",
    }

    local definitions = types.resolve()

    assert.same({
      ["@test"] = "/path/to/test.d.luau",
    }, definitions)
  end)

  it_async("resolves documentation files", function()
    config.get().types.documentation_files = {
      "/path/to/docs.json",
    }

    local _, documentation = types.resolve()

    assert.is_true(vim.tbl_contains(documentation, "/path/to/docs.json"))
  end)
end)
