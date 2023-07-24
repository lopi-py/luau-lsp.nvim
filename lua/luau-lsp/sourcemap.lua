local Job = require "plenary.job"
local c = require "luau-lsp.config"
local util = require "luau-lsp.util"

local job_id = nil

local M = {}

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

  vim.api.nvim_create_user_command("RojoSourcemap", function()
    M.generate()
  end, {})
end

function M.generate()
  if not c.get().sourcemap.enabled or job_id then
    return
  end

  local args = { "sourcemap", c.get().sourcemap.rojoProjectFile, "-o", "sourcemap.json" }

  if c.get().sourcemap.includeNonScripts then
    table.insert(args, "--include-non-scripts")
  end

  if c.get().sourcemap.autogenerate then
    table.insert(args, "--watch")
  end

  job_id = Job:new({
    command = c.get().sourcemap.rojoPath or "rojo",
    args = args,
    on_exit = function(self, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify(
            table.concat(self:stderr_result(), "\n"),
            vim.log.levels.ERROR,
            { title = "luau lsp" }
          )
        end)
      end

      job_id = nil
    end,
  }):start()
end

return M
