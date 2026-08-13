---@class luau-lsp.roblox.http.Request
---@field method vim.net.HttpMethod
---@field path string
---@field headers table<string, string>
---@field body string

local STATUS_PHRASES = {
  [200] = "OK",
  [202] = "Accepted",
  [400] = "Bad Request",
  [404] = "Not Found",
  [500] = "Internal Server Error",
}

local M = {}

---@param request_header string
---@return luau-lsp.roblox.http.Request?
local function parse_request_header(request_header)
  local request = {
    method = "",
    path = "",
    headers = {},
    body = "",
  }

  for line in request_header:gmatch "([^\r\n]+)\r\n" do
    local name, value = line:match "^([^:]+):%s*(.*)$"
    if name and value then
      request.headers[name:lower()] = value
    else
      local method, target = line:match "^(%w+) (.+) HTTP/%d%.%d$"
      if not method or not target then
        return
      end
      request.method = method
      request.path = target:match "^[^?]+"
    end
  end

  return request
end

function M.create_request_parser()
  local buffer = ""

  ---@param chunk string
  return function(chunk)
    buffer = buffer .. chunk

    local _, header_end = string.find(buffer, "\r\n\r\n", 1, true)
    if not header_end then
      return
    end

    local request = parse_request_header(buffer:sub(1, header_end))
    if not request then
      return
    end

    local content_length = assert(tonumber(request.headers["content-length"] or "0"))
    local content_end = header_end + content_length

    if #buffer < content_end then
      return
    end

    request.body = buffer:sub(header_end + 1, content_end)
    buffer = buffer:sub(content_end + 1)

    return request
  end
end

---@param headers table<string, string>
---@param body string
---@param status integer
---@return string
function M.create_response(headers, body, status)
  local response_headers = {}
  for name, value in pairs(headers) do
    response_headers[name:lower()] = value
  end

  local lines = {
    string.format("HTTP/1.1 %d %s", status, STATUS_PHRASES[status]),
    string.format("content-length: %d", #body),
  }

  if not response_headers["content-type"] then
    table.insert(lines, "content-type: text/plain")
  end

  for name, value in pairs(response_headers) do
    table.insert(lines, string.format("%s: %s", name, value))
  end

  return table.concat(lines, "\r\n") .. "\r\n\r\n" .. body
end

return M
