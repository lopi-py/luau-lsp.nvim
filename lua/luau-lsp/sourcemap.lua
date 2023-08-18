local Job = require "plenary.job"
local c = require "luau-lsp.config"
local log = require "luau-lsp.log"

local job_id = nil

local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("luau-lsp.sourcemap", { clear = true })

  if c.get().sourcemap.enabled then
    vim.api.nvim_create_autocmd("LspAttach", {
      group = group,
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client or client.name ~= "luau_lsp" then
          return
        end
        M.watch()
      end,
    })
  end
end

function M.watch()
  if not c.get().sourcemap.enabled or job_id then
    return
  end

  local args = {
    "sourcemap",
    "--watch",
    c.get().sourcemap.rojo_project_file,
    "-o",
    "sourcemap.json",
  }

  if c.get().sourcemap.include_non_scripts then
    table.insert(args, "--include-non-scripts")
  end

  job_id = Job:new({
    command = c.get().sourcemap.rojo_path or "rojo",
    args = args,
    on_exit = function(self, code)
      if code ~= 0 then
        vim.schedule(function()
          log.error(table.concat(self:stderr_result(), "\n"))
        end)
      end

      job_id = nil
    end,
  }):start()
end

return M
