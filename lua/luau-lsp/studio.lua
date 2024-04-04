local compat = require "luau-lsp.compat"
local config = require "luau-lsp.config"
local http = require "luau-lsp.http"
local uv = compat.uv

-- Acknowledgements:
-- https://github.com/zilibobi/luau-tree.nvim/tree/main
-- https://github.com/JohnnyMorganz/luau-lsp/blob/main/editors/code/src/extension.ts
-- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/rpc.lua

local is_listening = false

local server
local socket

local data_model

local function send_status(target_socket, status, body)
  local response = http.create_response({}, body or "", status)
  target_socket:write(response)
end

local M = {}

local start_server = function(port)
  assert(type(port) == "number", "Port must be a number")
  assert(is_listening == false, "This server object is already bound to http://localhost:" .. port)

  is_listening = true

  server = uv.new_tcp()

  server:bind("127.0.0.1", port)

  server:listen(128, function(listen_err)
    assert(not listen_err, listen_err)

    print("Luau Language Server Studio Plugin is now listening on port " .. port)

    socket = uv.new_tcp()

    server:accept(socket)

    local parse_chunk = coroutine.wrap(http.request_parser_loop)
    parse_chunk()

    socket:read_start(function(read_err, chunk)
      assert(not read_err, read_err)

      if chunk then
        while true do
          local metadata, _, body = parse_chunk(chunk)

          local client = compat.get_clients({ name = "luau_lsp" })[1]

          if not metadata then
            return
          end

          if not client then
            send_status(socket, 500)
            return
          end

          if metadata.path == "/full" then
            data_model = vim.json.decode(body).tree

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

    is_listening = false
    print "Luau Language Server Studio Plugin has disconnected"
  end
end

local function restart_server()
  stop_server()
  start_server(config:get().companion.port)
end

M.setup = function()
  if config.get().companion.enabled then
    start_server(config.get().companion.port)
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = compat.get_clients({ id = args.data.client_id })[1]

      if not client or client.name ~= "luau_lsp" then
        return
      end

      if data_model then
        client.notify("$/plugin/full", data_model)
      else
        client.notify "$/plugin/clear"
      end
    end,
  })

  config.on("companion.enabled", function()
    if config.get().companion.enabled and not is_listening then
      restart_server()
    elseif not config.get().companion.enabled and is_listening then
      stop_server()
    end
  end)

  config.on("companion.port", restart_server)
end

return M
