-- Acknowledgements:
-- https://github.com/zilibobi/luau-tree.nvim/tree/main
-- https://github.com/JohnnyMorganz/luau-lsp/blob/main/editors/code/src/extension.ts
-- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/rpc.lua

local config = require "luau-lsp.config"
local http = require "luau-lsp.http"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"
local wsl = require "luau-lsp.roblox.wsl"

local M = {}

---@type uv.uv_tcp_t?
local server

---@param socket uv.uv_tcp_t
---@param status number
---@param body? string
---@param content_type? string
local function send_response(socket, status, body, content_type)
  local headers = {}
  if content_type then
    headers["content-type"] = content_type
  end
  local response = http.create_response(headers, body or "", status)
  socket:write(response)
  socket:close()
end

---@param socket uv.uv_tcp_t
---@param metadata table
---@param headers table
---@param body string
local function handle_request(socket, metadata, headers, body)
  local client = util.get_client()
  if not client then
    send_response(socket, 500)
    return
  end

  if metadata.path == "/full" then
    http.decompress(headers, body, function(res)
      if client:is_stopped() then
        send_response(socket, 500)
      elseif res.tree then
        wsl.normalize_file_paths(res.tree)
        client:notify("$/plugin/full", res.tree)
        send_response(socket, 200)
      else
        send_response(socket, 400)
      end
    end)
  elseif metadata.path == "/clear" then
    client:notify "$/plugin/clear"
    send_response(socket, 200)
  elseif metadata.path == "/get-file-paths" then
    vim.schedule(function()
      local res = vim.json.encode { files = wsl.find_luau_files() }
      send_response(socket, 200, res, "application/json")
    end)
  else
    send_response(socket, 404)
  end
end

local function stop_server()
  if server then
    server:shutdown()
    server = nil
    log.info "Plugin server has disconnected"
  end
end

---@param port number
local function start_server(port)
  server = assert(vim.uv.new_tcp())
  server:bind("127.0.0.1", port)
  server:listen(128, function(listen_err)
    if listen_err then
      log.error(listen_err)
    else
      local parse_chunk = coroutine.wrap(http.request_parser_loop)
      parse_chunk()

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

        local metadata, headers, body = parse_chunk(chunk)
        if not metadata or not headers or not body then
          return
        end

        handle_request(socket, metadata, headers, body)
      end)
    end
  end)

  log.info("Plugin server is now listening on port " .. port)
end

function M.start()
  stop_server()
  start_server(config.get().plugin.port)
end

return M
