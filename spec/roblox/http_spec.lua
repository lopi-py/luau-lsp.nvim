local http = require "luau-lsp.roblox.http"

describe("roblox.http.create_request_parser", function()
  it("does not parse request body bytes as headers", function()
    local parse_chunk = http.create_request_parser()
    local body = "GET /wrong HTTP/1.1\r\nContent-Length: 999\r\n"
    local raw_request =
      string.format("POST /full HTTP/1.1\r\nContent-Length: %d\r\n\r\n%s", #body, body)

    local request = parse_chunk(raw_request)
    assert(request, "expected complete request")

    assert.equal("POST", request.method)
    assert.equal("/full", request.path)
    assert.equal(tostring(#body), request.headers["content-length"])
    assert.equal(body, request.body)
  end)

  it("waits for the full body across chunks", function()
    local parse_chunk = http.create_request_parser()
    local body = "hello world"
    local header = string.format("POST /full HTTP/1.1\r\nContent-Length: %d\r\n\r\n", #body)

    assert.is_nil(parse_chunk(header .. body:sub(1, 5)))

    local request = parse_chunk(body:sub(6))
    assert(request, "expected complete request")

    assert.equal("POST", request.method)
    assert.equal("/full", request.path)
    assert.equal(body, request.body)
  end)
end)
