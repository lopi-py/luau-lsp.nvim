local Job = require "plenary.job"
local async = require "plenary.async"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local job = nil

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

  log.info("Starting sourcemap generation for `%s`", project_file)

  job = Job:new {
    command = config.get().sourcemap.rojo_path,
    args = args,
    on_exit = function(self, code)
      if code and code ~= 0 then
        local err = table.concat(self:stderr_result(), "\n")
        log.error("Failed to update sourcemap for `%s`: %s", project_file, err)
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

local M = {}

---@return vim.Version
function M.version()
  local result = Job:new({
    command = config.get().sourcemap.rojo_path,
    args = { "--version" },
  }):sync()

  local version = vim.version.parse(result[1])
  assert(version, "could not parse rojo version")

  return version
end

M.start = async.void(function(project_file)
  stop_sourcemap_generation()
  start_sourcemap_generation(project_file or get_rojo_project_file())
end)

return M
