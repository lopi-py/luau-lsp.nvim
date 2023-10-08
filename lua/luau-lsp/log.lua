local M = {}

local plugin_name = "luau-lsp.nvim"

function M.info(msg, ...)
  vim.notify(msg:format(...), vim.lsp.log_levels.INFO, { title = plugin_name })
end

function M.error(msg, ...)
  vim.notify(msg:format(...), vim.lsp.log_levels.ERROR, { title = plugin_name })
end

return M
