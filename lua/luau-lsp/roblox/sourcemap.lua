local async = require "plenary.async"
local config = require "luau-lsp.config"
local log = require "luau-lsp.log"
local util = require "luau-lsp.util"

local M = {}

---@type number?
local pid

local function get_rojo_project_files()
  local project_files = vim.split(vim.fn.glob "*.project.json", "\n")
  table.sort(project_files)
  return vim.tbl_filter(util.is_file, project_files)
end

---@param callback fun(project_file: string?)
local get_rojo_project_file = async.wrap(function(callback)
  local project_file = config.get().sourcemap.rojo_project_file
  if util.is_file(project_file) then
    callback(project_file)
    return
  end

  local found_project_files = get_rojo_project_files()
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
end, 1)

---@async
local function get_rojo_generator_cmd()
  local project_file = get_rojo_project_file()
  if not project_file then
    return
  end

  local cmd = {
    config.get().sourcemap.rojo_path,
    "sourcemap",
    "--watch",
    "--output",
    config.get().sourcemap.sourcemap_file,
    project_file,
  }

  if config.get().sourcemap.include_non_scripts then
    table.insert(cmd, "--include-non-scripts")
  end

  return cmd
end

local function stop_sourcemap_generation()
  if pid then
    vim.uv.kill(pid, "sigterm")
  end
end

---@param cmd string[]
local function start_sourcemap_generation(cmd)
  local ok, job = pcall(vim.system, cmd, { text = true }, function(result)
    if result.stderr and result.stderr ~= "" then
      log.error("Failed to update sourcemap: %s", result.stderr)
    end
  end)

  if not ok then
    log.error("Failed to start command: '%s'", cmd[1])
    return
  end

  log.info "Starting sourcemap generation"
  pid = job.pid

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("luau-lsp.sourcemap", {}),
    callback = stop_sourcemap_generation,
  })
end

M.start = async.void(function()
  local cmd = config.get().sourcemap.generator_cmd or get_rojo_generator_cmd()
  if cmd then
    stop_sourcemap_generation()
    start_sourcemap_generation(cmd)
  end
end)

return M
