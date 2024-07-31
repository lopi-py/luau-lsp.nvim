local command = require "luau-lsp.command"
local compat = require "luau-lsp.compat"

describe("command executor", function()
  it("should provide completion for regenerate_sourcemap", function()
    local cwd = compat.uv.cwd()
    assert(cwd)

    compat.uv.chdir(cwd .. "/spec/roblox-project")

    local items1 = command.complete("reg", "LuauLsp reg")
    local items2 = command.complete("", "LuauLsp regenerate_sourcemap ")
    local items3 = command.complete("serv", "LuauLsp regenerate_sourcemap serv")

    compat.uv.chdir(cwd)

    assert.same({ "regenerate_sourcemap" }, items1)
    assert.same({ "dev.project.json", "serve.project.json" }, items2)
    assert.same({ "serve.project.json" }, items3)
  end)
end)
