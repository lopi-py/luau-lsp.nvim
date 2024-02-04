local Job = require "plenary.job"
local Path = require "plenary.path"
local async = require "plenary.async"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"

local job = nil

local M = {}

local get_rojo_project_file = async.wrap(function(callback)
  local project_file = config.get().sourcemap.rojo_project_file
  if Path:new(project_file):is_file() then
    callback(project_file)
    return
  end

  local found_project_files = vim.split(vim.fn.glob "*.project.json", "\n")
  if #found_project_files == 0 or #found_project_files[1] == "" then
    log.warn("Unable to find project file `%s`", project_file)
    callback()
  elseif #found_project_files == 1 then
    log.info(
      "Unable to find project file `%s`. We found `%s`",
      project_file,
      found_project_files[1]
    )
    callback(found_project_files[1])
  else
    vim.ui.select(found_project_files, { prompt = "Select project file" }, function(choice)
      if choice and choice ~= "" then
        callback(choice)
      else
        callback()
      end
    end)
  end
end, 1)

local function start(project_file)
  local args = {
    "sourcemap",
    "--watch",
    project_file,
    "-o",
    "sourcemap.json",
  }

  if config.get().sourcemap.include_non_scripts then
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
    command = config.get().sourcemap.rojo_path or "rojo",
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

M.start = async.void(function(project_file)
  project_file = project_file or get_rojo_project_file()

  if project_file then
    start(project_file)
  end
end)

function M.is_running()
  return job ~= nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup("luau-lsp.sourcemap", {})

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.name == "luau_lsp" then
        if config.get().sourcemap.enabled and config.get().sourcemap.autogenerate then
          M.stop()
          M.start()
          return true
        end
      end
    end,
  })

  config.on("sourcemap.rojo_project_file", function()
    if config.get().sourcemap.enabled and config.get().sourcemap.autogenerate then
      M.stop()
      M.start()
    else
      M.stop()
    end
  end)
end

return M
