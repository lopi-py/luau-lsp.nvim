local Job = require "plenary.job"
local async = require "plenary.async"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local job = nil

local M = {}

local get_rojo_project_file = async.wrap(function(callback)
  local project_file = config.get().sourcemap.rojo_project_file
  if util.is_file(project_file) then
    callback(project_file)
    return
  end

  local found_project_files = vim.split(vim.fn.glob "*.project.json", "\n")
  if #found_project_files == 0 or found_project_files[1] == "" then
    log.error("Unable to find project file `%s`", project_file)
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

local function start_sourcemap_generation(project_file)
  if not project_file then
    return
  end

  local args = {
    "sourcemap",
    "--watch",
    project_file,
    "--output",
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
    elseif err:find "is not recognized" or err:find "not found" or err:find "ENOENT" then
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

local function stop_sourcemap_generation()
  if job then
    job:shutdown()
  end
end

M.start = async.void(function(project_file)
  stop_sourcemap_generation()
  start_sourcemap_generation(project_file or get_rojo_project_file())
end)

function M.setup()
  vim.api.nvim_create_user_command("LuauRegenerateSourcemap", function(data)
    if data.args ~= "" then
      if not util.is_file(data.args) then
        log.error "Invalid project file provided"
        return
      end

      M.start(data.args)
    else
      M.start()
    end
  end, {
    complete = "file",
    nargs = "?",
  })

  config.on("sourcemap.autogenerate", function()
    if config.get().sourcemap.enabled and config.get().sourcemap.autogenerate then
      M.start()
    else
      stop_sourcemap_generation()
    end
  end)

  config.on("sourcemap.rojo_project_file", function()
    if config.get().sourcemap.enabled and config.get().sourcemap.autogenerate then
      M.start()
    else
      stop_sourcemap_generation()
    end
  end)
end

return M
