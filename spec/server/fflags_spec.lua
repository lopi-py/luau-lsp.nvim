local config = require "luau-lsp.config"
local fflags = require "luau-lsp.server.fflags"
local log = require "luau-lsp.log"
local test_util = require "spec.test_util"

local it_async = test_util.it_async

describe("server.fflags.resolve", function()
  local original_sync
  local original_enable_new_solver
  local original_override
  local request_handler

  before_each(function()
    original_sync = config.get().fflags.sync
    original_enable_new_solver = config.get().fflags.enable_new_solver
    original_override = vim.deepcopy(config.get().fflags.override)

    config.get().fflags.sync = false
    config.get().fflags.enable_new_solver = false

    request_handler = function()
      error "unexpected network request"
    end

    stub(vim.net, "request", function(...)
      return request_handler(...)
    end)
    stub(log, "error")
  end)

  after_each(function()
    config.get().fflags.sync = original_sync
    config.get().fflags.enable_new_solver = original_enable_new_solver
    config.get().fflags.override = original_override

    vim.net.request:revert()
    log.error:revert()
  end)

  it("resolves Luau overrides to server fflags", function()
    config.get().fflags.override = {
      FFlagLuauTest = true,
      FIntLuauFoo = 10,
      DFFlagLuauBar = "value",
      DFIntLuauAnotherFlag = 42,
      LuauDirect = false,
      FFlagUnrelated = true,
    }

    assert.same({
      LuauTest = "true",
      LuauFoo = "10",
      LuauBar = "value",
      LuauAnotherFlag = "42",
      LuauDirect = "false",
    }, fflags.resolve())
  end)

  it_async("merges synchronized flags with local overrides", function()
    config.get().fflags.sync = true
    config.get().fflags.override = {
      FFlagLuauOverridden = true,
    }

    local requested_url
    local requested_options
    request_handler = function(url, options, callback)
      requested_url = url
      requested_options = options
      callback(nil, {
        body = vim.json.encode {
          applicationSettings = {
            FFlagLuauSynced = true,
            FIntLuauCount = 3,
            FFlagLuauOverridden = false,
          },
        },
      })
    end

    assert.same({
      LuauSynced = "true",
      LuauCount = "3",
      LuauOverridden = "true",
    }, fflags.resolve())
    assert.equal(
      "https://clientsettingscdn.roblox.com/v1/settings/application?applicationName=PCStudioApp",
      requested_url
    )
    assert.same({}, requested_options)
  end)

  it_async("preserves local overrides when synchronization fails", function()
    config.get().fflags.sync = true
    config.get().fflags.override = {
      LuauLocal = true,
    }

    request_handler = function(_, _, callback)
      callback "network unavailable"
    end

    assert.same({
      LuauLocal = "true",
    }, fflags.resolve())
  end)
end)
