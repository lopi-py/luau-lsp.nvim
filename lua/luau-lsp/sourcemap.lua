local Job = require "plenary.job"
local config = require "luau-lsp.config"
local util = require "luau-lsp.util"

local M = {}

local function autogenerate()
  util.autocmd({ "BufWritePost", "BufDelete" }, {
    pattern = "*.luau,*.json",
    callback = function(event)
      local match = event.match
      local clients = vim.lsp.get_active_clients {
        name = "luau_lsp",
      }

      local should_generate = false

      for _, client in ipairs(clients) do
        local workspace = client.workspace_folders[1]
        for dir in vim.fs.parents(match) do
          if dir == workspace.name then
            should_generate = true
            break
          end
        end
        if should_generate then
          break
        end
      end

      if should_generate then
        M.generate()
      end
    end,
  })
end

function M.setup()
  util.autocmd("LspAttach", {
    callback = function(event)
      if event.data and event.data.client_id then
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client.name == "luau_lsp" then
          M.generate()
        end
      end
    end,
  })

  if config.get().sourcemap.autogenerate then
    autogenerate()
  end
end

function M.generate()
  if not config.get().sourcemap.enabled then
    return
  end

  local project_file = config.get().sourcemap.rojo_project_file
  local include_non_scripts = config.get().sourcemap.include_non_scripts

  local args = { "sourcemap", project_file, "-o", "sourcemap.json" }

  if include_non_scripts then
    table.insert(args, "--include-non-scripts")
  end

  Job:new({
    command = config.get().sourcemap.rojo_path,
    args = args,
    on_exit = function(self, code)
      if code ~= 0 then
        vim.notify(self:stderr_result(), vim.log.levels.ERROR, { title = "luau lsp" })
      end
    end,
  }):start()
end

return M
