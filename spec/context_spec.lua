local Context = require "luau-lsp.context"

describe("context", function()
  it("should add fflags correctly", function()
    local ctx = Context.new()
    ctx:add_fflag("FFlagLuauTest", true)
    ctx:add_fflag("FIntLuauFoo", 10)
    ctx:add_fflag("DFFlagLuauBar", "value")
    ctx:add_fflag("DFIntLuauAnotherFlag", 42)
    ctx:add_fflag("LuauAnotherBaz", "baz")
    ctx:add_fflag("SomeOtherFlag", false)
    ctx:add_fflag("UnknownLuauFlag", 123)

    assert.same({
      LuauTest = "true",
      LuauFoo = "10",
      LuauBar = "value",
      LuauAnotherFlag = "42",
      LuauAnotherBaz = "baz",
    }, ctx.fflags)
  end)

  it("should add definitions correctly", function()
    local ctx = Context.new()
    ctx:add_definitions("mydef", "/path/to/mydef.d.luau")
    ctx:add_definitions("@anotherdef", "/path/to/anotherdef.d.luau")

    assert.same({
      ["@mydef"] = "/path/to/mydef.d.luau",
      ["@anotherdef"] = "/path/to/anotherdef.d.luau",
    }, ctx.definitions)
  end)

  it("should add documentation correctly", function()
    local ctx = Context.new()
    ctx:add_documentation "/path/to/doc1.md"
    ctx:add_documentation "/path/to/doc2.md"

    assert.same({
      "/path/to/doc1.md",
      "/path/to/doc2.md",
    }, ctx.documentation)
  end)
end)
