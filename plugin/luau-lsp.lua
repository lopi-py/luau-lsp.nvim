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
  once = true,
  pattern = "luau",
  callback = function()
    require("luau-lsp.server").setup()
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
