local json = require "luau-lsp.json"

describe("json5 decoder", function()
  it("should decode with comments", function()
    local success, contents = pcall(
      json.decode,
      [[
      // .luaurc
      {
        // add some fields
        "foo": "foo",
        "bar": "bar"
      }
      ]]
    )

    assert.is_true(success)
    assert.same({
      foo = "foo",
      bar = "bar",
    }, contents)
  end)

  it("should decode with trailing commas", function()
    local success, contents = pcall(
      json.decode,
      [[
      {
        "foo": "foo",
        "bar": "bar",
      }
      ]]
    )

    assert.is_true(success)
    assert.same({
      foo = "foo",
      bar = "bar",
    }, contents)
  end)
end)
