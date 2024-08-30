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
