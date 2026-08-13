local script_sync = require "luau-lsp.roblox.script_sync"
local wsl = require "luau-lsp.roblox.wsl"

describe("roblox.script_sync.normalize_file_paths", function()
  local original_is_wsl

  before_each(function()
    original_is_wsl = wsl.is_wsl
  end)

  after_each(function()
    wsl.is_wsl = original_is_wsl
  end)

  it("converts Studio tree paths to editor paths under WSL", function()
    wsl.is_wsl = true

    local tree = {
      FilePaths = { "C:\\project\\src\\init.luau" },
      Children = {
        { FilePaths = { "D:\\project\\src\\module.lua" } },
        {
          Name = "Folder",
          Children = {
            { FilePaths = { "E:\\project\\src\\nested.lua" } },
          },
        },
      },
    }

    script_sync.normalize_file_paths(tree)

    assert.same({
      FilePaths = { "/mnt/c/project/src/init.luau" },
      Children = {
        { FilePaths = { "/mnt/d/project/src/module.lua" } },
        {
          Name = "Folder",
          Children = {
            { FilePaths = { "/mnt/e/project/src/nested.lua" } },
          },
        },
      },
    }, tree)
  end)
end)
