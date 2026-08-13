local wsl = require "luau-lsp.roblox.wsl"

describe("roblox.wsl", function()
  local original_is_wsl

  before_each(function()
    original_is_wsl = wsl.is_wsl
  end)

  after_each(function()
    wsl.is_wsl = original_is_wsl
  end)

  it("leaves paths unchanged outside WSL", function()
    wsl.is_wsl = false

    assert.equal(
      "/mnt/c/project/src/init.luau",
      wsl.to_windows_path "/mnt/c/project/src/init.luau"
    )
    assert.equal("C:\\project\\src\\init.luau", wsl.to_wsl_path "C:\\project\\src\\init.luau")
  end)

  it("converts WSL paths to Windows paths", function()
    wsl.is_wsl = true

    assert.equal("C:\\project\\src\\init.luau", wsl.to_windows_path "/mnt/c/project/src/init.luau")
    assert.equal("D:\\project\\src\\init.luau", wsl.to_windows_path "/mnt/D/project/src/init.luau")
    assert.equal("/home/me/init.luau", wsl.to_windows_path "/home/me/init.luau")
  end)

  it("converts Windows paths to WSL paths", function()
    wsl.is_wsl = true

    assert.equal("/mnt/c/project/src/init.luau", wsl.to_wsl_path "C:\\project\\src\\init.luau")
    assert.equal("/mnt/d/project/src/init.luau", wsl.to_wsl_path "d:\\project\\src\\init.luau")
    assert.equal("relative\\init.luau", wsl.to_wsl_path "relative\\init.luau")
  end)
end)
