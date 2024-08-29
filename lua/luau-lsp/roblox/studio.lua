-- Acknowledgements:
-- https://github.com/zilibobi/luau-tree.nvim/tree/main
-- https://github.com/JohnnyMorganz/luau-lsp/blob/main/editors/code/src/extension.ts
-- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/rpc.lua

local config = require "luau-lsp.config"
local http = require "luau-lsp.http"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local is_listening = false

local server
local socket

local current_port = config.get().plugin.port

---@param target_socket uv_tcp_t
---@param status number
---@param body? string
local function send_status(target_socket, status, body)
  local response = http.create_response({}, body or "", status)
  target_socket:write(response)
end

local M = {}

---@param port number
local function start_server(port)
  assert(type(port) == "number", "Port must be a number")
  assert(is_listening == false, "This server object is already bound to http://localhost:" .. port)

  is_listening = true
  current_port = port

  server = vim.uv.new_tcp()
  server:bind("127.0.0.1", port)

  log.info("Plugin server listening on port " .. port)

  server:listen(128, function(listen_err)
    assert(not listen_err, listen_err)

    socket = vim.uv.new_tcp()
    server:accept(socket)

    local parse_chunk = coroutine.wrap(http.request_parser_loop)
    parse_chunk()

    socket:read_start(function(read_err, chunk)
      assert(not read_err, read_err)

      if chunk then
        while true do
          local metadata, headers, body = parse_chunk(chunk)
          local client = util.get_client()

          if not metadata then
            return
          end

          if not client then
            send_status(socket, 500)
            return
          end

          if metadata.path == "/full" then
            local data_model = headers.content_encoding == "gzip" and http.decompress(body).tree
              or vim.json.decode(body).tree

            if not data_model then
              send_status(socket, 400)
              break
            end

            client.notify("$/plugin/full", data_model)
            send_status(socket, 200)
          elseif metadata.path == "/clear" then
            client.notify "$/plugin/clear"
            send_status(socket, 200)
          else
            send_status(socket, 404)
            break
          end
          chunk = ""
        end
      else
        socket:close()
      end
    end)
  end)
end

local function stop_server()
  if is_listening then
    server:shutdown()

    if socket then
      socket:shutdown()
    end

    local client = util.get_client()
    if client then
      client.notify "$/plugin/clear"
    end

    is_listening = false
    log.info("Plugin server disconnected from port " .. current_port)
  end
end

function M.start()
  stop_server()
  start_server(config.get().plugin.port)
end

return M
