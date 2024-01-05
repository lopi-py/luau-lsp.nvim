local Job = require "plenary.job"
local Path = require "plenary.path"
local c = require "luau-lsp.config"
local log = require "luau-lsp.log"

local job = nil

local M = {}

local function get_rojo_project_file(callback)
  local project_file = c.get().sourcemap.rojo_project_file
  if Path:new(project_file):is_file() then
    callback(project_file)
    return
  end

  local foundProjectFiles = vim.split(vim.fn.glob "*.project.json", "\n")
  if #foundProjectFiles == 0 then
    log.warn("Unable to find project file `%s`", project_file)
    callback()
  elseif #foundProjectFiles == 1 then
    log.info("Unable to find project file `%s`. We found `%s`", project_file, foundProjectFiles[1])
    callback(foundProjectFiles[1])
  else
    vim.ui.select(foundProjectFiles, { prompt = "Select project file" }, function(choice)
      if choice and choice ~= "" then
        callback(choice)
      else
        callback()
      end
    end)
  end
end

local function start(project_file)
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

  ---@param err string
  local function on_error(err)
    local message = err
    if err:find "Found argument 'sourcemap' which wasn't expected" then
      message = "Your Rojo version doesn't have sourcemap support"
    elseif err:find "Found argument '--watch' which wasn't expected" then
      message = "Your Rojo version doesn't have sourcemap watching support"
    elseif err:find "is not recognized" or err:find "ENOENT" then
      message = "Rojo not found. Please install Rojo or disable sourcemap autogeneration"
    end

    log.error("Failed to update sourcemap for `%s`: %s", project_file, message)
  end

  log.info("Starting sourcemap generation for `%s`", project_file)

  job = Job:new {
    command = c.get().sourcemap.rojo_path or "rojo",
    args = args,
    on_exit = function(self, code)
      if code and code ~= 0 then
        local err = table.concat(self:stderr_result(), "\n")
        on_error(err)
      end

      job = nil
    end,
  }
  job:start()
end

function M.stop()
  if job then
    job:shutdown()
  end
end

function M.start()
  if not c.get().sourcemap.enabled then
    return
  end

  get_rojo_project_file(function(project_file)
    if project_file then
      start(project_file)
    end
  end)
end

function M.is_running()
  return job ~= nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup("luau-lsp.sourcemap", { clear = true })

  if c.get().sourcemap.enabled then
    vim.api.nvim_create_autocmd("LspAttach", {
      group = group,
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == "luau_lsp" then
          if c.get().sourcemap.enabled and c.get().sourcemap.autogenerate then
            M.start()
            return true
          end
        end
      end,
    })
  end

  vim.api.nvim_create_user_command("LuauRegenerateSourcemap", function(data)
    if data.args ~= "" then
      if not Path:new(data.args):is_file() then
        log.error "Invalid project file provided"
        return
      end

      if c.get().sourcemap.rojo_project_file == data.args then
        return
      end

      c.get().sourcemap.rojo_project_file = data.args
    end

    M.stop()
    M.start()
  end, { complete = "file", nargs = "?" })
end

return M
