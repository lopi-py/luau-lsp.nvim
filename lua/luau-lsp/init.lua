local log = require "luau-lsp.log"

local M = {}

function M.bytecode()
  require("luau-lsp.bytecode").bytecode()
end

function M.compiler_remarks()
  require("luau-lsp.bytecode").compiler_remarks()
end

function M.open_logs()
  vim.cmd.edit(log.log_file)
end

function M.treesitter()
  log.warn "A custom treesitter parser is not longer required at all"
end

---@param opts LuauLspConfig
function M.config(opts)
  require("luau-lsp.config").config(opts)
end

---@param opts? LuauLspConfig
function M.setup(opts)
  require("luau-lsp.config").setup(opts)

  vim.api.nvim_create_user_command("LuauBytecode", M.bytecode, {})
  vim.api.nvim_create_user_command("LuauCompilerRemarks", M.compiler_remarks, {})
end

return M
