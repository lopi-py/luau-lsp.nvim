describe(".luaurc", function()
  it("should find a .luaurc file", function()
    local path = require("luau-lsp.luaurc").find_luaurc {
      "spec/roblox-project",
      "spec/roblox-project/lib",
      "spec/roblox-project/src",
    }

    assert.same("spec/roblox-project/.luaurc", path)
  end)

  it("should read .luaurc aliases", function()
    local aliases = require("luau-lsp.luaurc").aliases {
      "spec/roblox-project",
      "spec/roblox-project/lib",
      "spec/roblox-project/src",
    }

    assert.same({
      ["@client"] = "src/client",
      ["@server"] = "src/server",
      ["@shared"] = "src/shared",
    }, aliases)
  end)
end)
