describe(".luaurc", function()
  it("should read .luaurc aliases", function()
    local aliases = require("luau-lsp").aliases {
      "spec/roblox-project/lib",
      "spec/roblox-project/src",
      "spec/roblox-project",
    }

    assert.same({
      ["@client"] = "src/client",
      ["@server"] = "src/server",
      ["@shared"] = "src/shared",
    }, aliases)
  end)
end)
