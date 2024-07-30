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

vim.api.nvim_create_user_command("LuauLsp", function(opts)
  require("luau-lsp.command").execute(opts.args)
end, {
  nargs = "+",
  complete = function(...)
    return require("luau-lsp.command").complete(...)
  end,
})

vim.api.nvim_create_user_command("LuauLog", function()
  require("luau-lsp.log").warn "`LuauLog` is deprecated, use `LuauLsp log` instead"
end, {})

vim.api.nvim_create_user_command("LuauBytecode", function()
  require("luau-lsp.log").warn "`LuauBytecode` is deprecated, use `LuauLsp bytecode` instead"
end, {})

vim.api.nvim_create_user_command("LuauCompilerRemarks", function()
  require("luau-lsp.log").warn "`LuauCompilerRemarks` is deprecated, use `LuauLsp compiler_remarks` instead"
end, {})

vim.api.nvim_create_user_command("LuauRegenerateSourcemap", function()
  require("luau-lsp.log").warn "`LuauRegenerateSourcemap` is deprecated, use `LuauLsp regenerate_sourcemap` instead"
end, {
  nargs = "?",
})
