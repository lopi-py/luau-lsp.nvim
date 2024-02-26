local compat = require "luau-lsp.compat"
local log = require "luau-lsp.log"

local M = {}

function M.setup()
  vim.api.nvim_create_user_command("LuauLog", function()
    vim.cmd.tabnew(log.log_file)
  end, {})

  vim.api.nvim_create_user_command("LuauBytecode", function()
    require("luau-lsp.bytecode").bytecode()
  end, {})

  vim.api.nvim_create_user_command("LuauCompilerRemarks", function()
    require("luau-lsp.bytecode").compiler_remarks()
  end, {})

  vim.api.nvim_create_user_command("LuauRegenerateSourcemap", function(data)
    local stat = compat.uv.fs_stat(data.args)
    if not stat or stat.type ~= "file" then
      log.error "Invalid project file provided"
      return
    end

    require("luau-lsp").config {
      sourcemap = {
        rojo_project_file = data.args,
      },
    }
  end, {
    complete = "file",
    nargs = "?",
  })
end

return M
