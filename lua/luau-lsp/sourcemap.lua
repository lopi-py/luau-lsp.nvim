local Job = require "plenary.job"
local Path = require "plenary.path"
local c = require "luau-lsp.config"
local log = require "luau-lsp.log"

local job = nil

local M = {}

local function select_project(callback)
  local projects = vim.split(vim.fn.glob "*.project.json", "\n")
  if #projects > 1 then
    vim.ui.select(projects, { prompt = "Rojo project" }, callback)
  else
    callback(projects[1])
  end
end

local function start(project_file)
  if not project_file then
    log.error "Rojo project not found"
    return
  end

  if not Path:new(project_file):is_file() then
    log.error("%s is not a file", project_file)
    return
  end

  local args = {
    "sourcemap",
    "--watch",
    project_file,
    "-o",
    "sourcemap.json",
  }

  if c.get().sourcemap.include_non_scripts then
    table.insert(args, "--include-non-scripts")
  end

  job = Job:new {
    command = c.get().sourcemap.rojo_path or "rojo",
    args = args,
    on_exit = function(self, code)
      if code and code ~= 0 then
        vim.schedule(function()
          log.error(table.concat(self:stderr_result(), "\n"))
        end)
      end

      job = nil
    end,
  }
  job:start()

  log.info("Sourcemap generation started for %s", project_file)
end

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

  vim.api.nvim_create_user_command("RojoSourcemap", function()
    M.stop()
    M.watch()
  end, {})
end

function M.stop()
  if job then
    job:shutdown()
  end
end

function M.watch()
  if not c.get().sourcemap.enabled or job then
    return
  end

  if c.get().sourcemap.select_project_file then
    start(c.get().sourcemap.select_project_file())
  else
    select_project(start)
  end
end

return M
