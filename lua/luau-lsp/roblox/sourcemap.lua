local Job = require "plenary.job"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local job = nil

local M = {}

---@return string[]
function M.get_rojo_project_files()
  local project_files = vim.split(vim.fn.glob "*.project.json", "\n")
  table.sort(project_files)
  return vim.tbl_filter(util.is_file, project_files)
end

---@param callback fun(project_file: string?)
local function get_rojo_project_file(callback)
  local project_file = config.get().sourcemap.rojo_project_file
  if util.is_file(project_file) then
    callback(project_file)
    return
  end

  local found_project_files = M.get_rojo_project_files()
  if #found_project_files == 0 then
    log.error("Unable to find project file '%s'", project_file)
    callback()
  elseif #found_project_files == 1 then
    log.info(
      "Unable to find project file '%s'. We found '%s'",
      project_file,
      found_project_files[1]
    )
    callback(found_project_files[1])
  else
    vim.ui.select(found_project_files, { prompt = "Select project file" }, callback)
  end
end

---@param project_file? string
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

  local ok
  ok, job = pcall(Job.new, Job, {
    command = config.get().sourcemap.rojo_path,
    args = args,
    on_exit = function(self, code)
      if code ~= 0 then
        local err = table.concat(self:stderr_result(), "\n")
        log.error("Failed to update sourcemap for '%s': %s", project_file, err)
      end
      job = nil
    end,
  })

  if not ok then
    log.error "rojo executable not found"
    return
  end

  log.info("Starting sourcemap generation for '%s'", project_file)
  job:start()
end

local function stop_sourcemap_generation()
  if job then
    job:shutdown()
  end
end

---@param project_file? string
function M.start(project_file)
  if project_file and not util.is_file(project_file) then
    log.error("Invalid project file '%s'", project_file)
    return
  end

  stop_sourcemap_generation()

  if project_file then
    start_sourcemap_generation(project_file)
  else
    get_rojo_project_file(start_sourcemap_generation)
  end
end

return M
