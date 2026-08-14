local config = require "luau-lsp.config"
local fflags = require "luau-lsp.server.fflags"
local test_util = require "spec.test_util"

local it_async = test_util.it_async

describe("server.fflags.resolve", function()
  before_each(function()
    config.config {
      fflags = {
        sync = false,
        enable_new_solver = false,
      },
    }
  end)

  after_each(function()
    config._reset()
  end)

  it("resolves Luau overrides to server fflags", function()
    config.config {
      fflags = {
        override = {
          FFlagLuauTest = true,
          FIntLuauFoo = 10,
          DFFlagLuauBar = "value",
          DFIntLuauAnotherFlag = 42,
          LuauDirect = false,
          FFlagUnrelated = true,
        },
      },
    }

    assert.same({
      LuauTest = "true",
      LuauFoo = "10",
      LuauBar = "value",
      LuauAnotherFlag = "42",
      LuauDirect = "false",
      ---@diagnostic disable-next-line: await-in-sync
    }, fflags.resolve())
  end)

  it_async("merges synchronized flags with local overrides", function()
    config.config {
      fflags = {
        sync = true,
        override = {
          FFlagLuauOverridden = true,
        },
      },
    }

    stub(vim.net, "request", function(_, _, callback)
      callback(nil, {
        body = vim.json.encode {
          applicationSettings = {
            FFlagLuauSynced = true,
            FIntLuauCount = 3,
            FFlagLuauOverridden = false,
          },
        },
      })
    end)
    finally(function()
      vim.net.request:revert()
    end)

    assert.same({
      LuauSynced = "true",
      LuauCount = "3",
      LuauOverridden = "true",
    }, fflags.resolve())
  end)
end)
