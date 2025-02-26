local STATUS_PRHASES = {
  [200] = "OK",
  [202] = "Accepted",
  [400] = "Bad Request",
  [404] = "Not Found",
  [500] = "Internal Server Error",
}

local M = {}

---@param header string
---@return table?
---@return table?
local function parse_headers(header)
  if header == "" then
    return
  end

  local headers = {}
  local metadata = {}

  for line in string.gmatch(header, "([^\r\n]+)\r\n") do
    local key, value = string.match(line, "(.+): (.+)")
    if key then
      key = string.lower(key):gsub("%-", "_")
      headers[key] = value
    else
      local method, place = string.match(line, "(%w+) (.+) HTTP/%d.%d")
      if method and place then
        local path, raw_queries = string.match(place, "([^%?]+)(.*)")
        local queries = {}

        if raw_queries then
          for query, query_value in string.gmatch(raw_queries, "(%w+)=([^&=]+)") do
            queries[query] = query_value
          end
        end

        metadata.method = method
        metadata.path = path
        metadata.queries = queries
      end
    end
  end

  return headers, metadata
end

function M.request_parser_loop()
  local buffer = ""

  while true do
    local start, finish = string.find(buffer, "\r\n\r\n", 1, true)
    if start then
      local headers, metadata = parse_headers(buffer)
      local content_length = headers and tonumber(headers.content_length) or 0
      local body_chunks = { string.sub(buffer, finish + 1) }
      local body_length = #body_chunks[1]

      while body_length < content_length do
        local chunk = coroutine.yield() or error "Expected more data for the body."
        table.insert(body_chunks, chunk)
        body_length = body_length + #chunk
      end

      local last_chunk = body_chunks[#body_chunks]
      body_chunks[#body_chunks] = string.sub(last_chunk, 1, content_length - body_length - 1)

      local remaining = ""
      if body_length > content_length then
        remaining = string.sub(last_chunk, content_length - body_length)
      end

      local body = table.concat(body_chunks)
      local chunk = coroutine.yield(metadata, headers, body)
        or error "Expected more data for the body."

      buffer = remaining .. chunk
    else
      local chunk = coroutine.yield() or error "Expected more chunks for the header"
      buffer = buffer .. chunk
    end
  end
end

---@param headers table
---@param body string
---@param status number
---@return string
function M.create_response(headers, body, status)
  local data = {
    "HTTP/1.1 " .. tostring(status) .. " " .. STATUS_PRHASES[status],
    "Content-Length: " .. tostring(string.len(body)),
    "",
    body,
  }

  if not headers["content-type"] then
    table.insert(data, 2, "Content-Type: text/plain")
  end

  for name, value in pairs(headers) do
    table.insert(data, 4, string.format("%s: %s", name, value))
  end

  return table.concat(data, "\r\n")
end

---@param headers table
---@param body string
---@param callback fun(ret: any)
function M.decompress(headers, body, callback)
  assert(headers.content_encoding == "gzip")

  local async
  async = assert(vim.uv.new_async(function(ret)
    callback(vim.mpack.decode(ret))
    async:close()
  end))

  ---@diagnostic disable-next-line: param-type-mismatch
  vim.uv.new_thread(function(body_data, async_handler)
    local zzlib = require "zzlib"
    local result = vim.json.decode(zzlib.gunzip(body_data))
    async_handler:send(vim.mpack.encode(result))
    ---@diagnostic disable-next-line: param-type-mismatch
  end, body, async)
end

return M
