---@class luau-lsp.View.Options
---@field name string
---@field augroup string
---@field cmd? string

---@class luau-lsp.View
---@field private bufnr integer
---@field private winnr integer
---@field private group integer
local View = {}
View.__index = View

---@return luau-lsp.View
function View.new()
  return setmetatable({
    bufnr = -1,
    winnr = -1,
    group = -1,
  }, View)
end

---@return boolean
function View:is_open()
  return vim.api.nvim_win_is_valid(self.winnr)
end

function View:close()
  if vim.api.nvim_win_is_valid(self.winnr) then
    pcall(vim.api.nvim_win_close, self.winnr, true)
  end
  if vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
end

---@param content string
function View:set_content(content)
  if not self:is_open() then
    return
  end

  local lines = vim.split(content, "\n", { trimempty = true })
  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
  vim.bo[self.bufnr].modifiable = false
end

---@param event vim.api.keyset.events | vim.api.keyset.events[]
---@param opts vim.api.keyset.create_autocmd
function View:autocmd(event, opts)
  opts.group = assert(self.group ~= -1 and self.group or nil)
  vim.api.nvim_create_autocmd(event, opts)
end

---@param opts luau-lsp.View.Options
function View:open(opts)
  local reuse = self:is_open()
    and vim.api.nvim_win_get_tabpage(self.winnr) == vim.api.nvim_get_current_tabpage()

  if not reuse then
    self:close()
    vim.cmd(opts.cmd or "belowright vnew")

    self.bufnr = vim.api.nvim_get_current_buf()
    self.winnr = vim.api.nvim_get_current_win()
  end

  local bufnr = self.bufnr
  local winnr = self.winnr
  local group = vim.api.nvim_create_augroup(opts.augroup, { clear = true })
  self.group = group

  vim.api.nvim_buf_set_name(bufnr, opts.name)
  vim.wo[winnr].winfixbuf = true
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].filetype = vim.filetype.match { buf = bufnr }

  vim.keymap.set("n", "q", function()
    self:close()
  end, { buffer = bufnr, desc = "Close the window" })

  self:autocmd("BufUnload", {
    buffer = bufnr,
    callback = function()
      self.bufnr = -1
      self.winnr = -1
      self.group = -1
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })

  if not reuse then
    vim.cmd.wincmd "p"
  end
end

return View
