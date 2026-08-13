local async = require "luau-lsp.async"
local config = require "luau-lsp.config"
local http = require "luau-lsp.roblox.http"
local log = require "luau-lsp.log"
local script_sync = require "luau-lsp.roblox.script_sync"
local util = require "luau-lsp.util"

local M = {}

---@type uv.uv_tcp_t?
local server

---@param headers table<string, string>
---@param body string
---@param callback fun(result: table)
local function decode_payload(headers, body, callback)
  assert(headers["content-encoding"] == "gzip")

  vim.uv
    .new_work(function(data)
      local zzlib = require "luau-lsp.vendor.zzlib"

      -- mpack cannot encode deeply nested tables
      local result = vim.json.decode(zzlib.gunzip(data))
      result = require("luau-lsp.util").truncate_table_depth(result, 30)

      return vim.mpack.encode(result)
    end, function(result)
      callback(vim.mpack.decode(result --[[@as string]]))
    end)
    :queue(body)
end

---@param socket uv.uv_tcp_t
---@param status integer
---@param body? string | table
local function send_response(socket, status, body)
  local headers = {}

  if type(body) == "table" then
    headers["content-type"] = "application/json"
    body = vim.json.encode(body)
  end

  local response = http.create_response(headers, body or "", status)
  socket:write(response, function()
    socket:close()
  end)
end

---@param socket uv.uv_tcp_t
---@param request luau-lsp.roblox.http.Request
local function handle_full(socket, request)
  local client = util.get_client()
  if not client then
    send_response(socket, 500)
    return
  end

  decode_payload(request.headers, request.body, function(result)
    if client:is_stopped() then
      send_response(socket, 500)
      return
    end

    local tree = result["tree"]
    if not tree then
      send_response(socket, 400)
      return
    end

    script_sync.normalize_file_paths(tree)
    client:notify("$/plugin/full", tree)
    send_response(socket, 200)
  end)
end

---@param socket uv.uv_tcp_t
local function handle_clear(socket)
  local client = util.get_client()
  if not client then
    send_response(socket, 500)
    return
  end

  client:notify "$/plugin/clear"
  send_response(socket, 200)
end

---@param socket uv.uv_tcp_t
local handle_get_file_paths = async.void(function(socket)
  local err, files = script_sync.find_script_files()
  if err then
    log.error(err)
    send_response(socket, 500, err)
    return
  end

  ---@cast files string[]
  send_response(socket, 200, { files = files })
end)

---@param socket uv.uv_tcp_t
---@param request luau-lsp.roblox.http.Request
local function handle_request(socket, request)
  if request.path == "/full" then
    handle_full(socket, request)
  elseif request.path == "/clear" then
    handle_clear(socket)
  elseif request.path == "/get-file-paths" then
    handle_get_file_paths(socket)
  else
    send_response(socket, 404)
  end
end

local function stop_server()
  if server then
    server:close()
    server = nil
    log.info "Plugin server has disconnected"
  end
end

---@param port integer
local function start_server(port)
  server = assert(vim.uv.new_tcp())
  server:bind("127.0.0.1", port)
  server:listen(128, function(listen_err)
    if listen_err then
      log.error(listen_err)
      return
    end

    local parse_chunk = http.create_request_parser()

    local socket = assert(vim.uv.new_tcp())
    server:accept(socket)
    socket:read_start(function(read_err, chunk)
      if read_err then
        socket:close()
        log.error(read_err)
        return
      end

      if not chunk then
        socket:close()
        return
      end

      local request = parse_chunk(chunk)
      if not request then
        return
      end

      handle_request(socket, request)
    end)
  end)

  log.info("Plugin server is now listening on port " .. port)
end

function M.start()
  stop_server()
  start_server(config.get().plugin.port)
end

return M
