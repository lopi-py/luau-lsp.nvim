local json = require "luau-lsp.json"

describe("json5 decoder", function()
  it("should decode with comments", function()
    local ok, contents = pcall(
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

    assert.is_true(ok)
    assert.same({
      foo = "foo",
      bar = "bar",
    }, contents)
  end)

  it("should decode with trailing commas", function()
    local ok, contents = pcall(
      json.decode,
      [[
      {
        "foo": "foo",
        "bar": "bar",
      }
      ]]
    )

    assert.is_true(ok)
    assert.same({
      foo = "foo",
      bar = "bar",
    }, contents)
  end)

  it("should decode nesting fields", function()
    local ok, contents = pcall(
      json.decode,
      [[
        {
          // nested
          "foo": {
            "bar": "baz",
          },
        }
      ]]
    )

    assert.is_true(ok)
    assert.same({
      foo = {
        bar = "baz",
      },
    }, contents)
  end)
end)
