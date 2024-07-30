if vim.version().minor < 10 then
  vim.filetype.add {
    extension = {
      luau = "luau",
    },
    filename = {
      [".luaurc"] = "jsonc",
    },
  }
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "luau",
  callback = function()
    require("luau-lsp.server").start()
  end,
})

vim.api.nvim_create_user_command("LuauLog", function()
  local log = require "luau-lsp.log"
  vim.cmd.tabnew(log.log_file)
end, {})

vim.api.nvim_create_user_command("LuauBytecode", function()
  require("luau-lsp.bytecode").bytecode()
end, {})

vim.api.nvim_create_user_command("LuauCompilerRemarks", function()
  require("luau-lsp.bytecode").compiler_remarks()
end, {})

vim.api.nvim_create_user_command("LuauRegenerateSourcemap", function(data)
  local util = require "luau-lsp.util"
  local log = require "luau-lsp.log"

  if data.args ~= "" then
    if not util.is_file(data.args) then
      log.error "Invalid project file provided"
      return
    end

    require("luau-lsp.sourcemap").start(data.args)
  else
    require("luau-lsp.sourcemap").start()
  end
end, {
  complete = "file",
  nargs = "?",
})
