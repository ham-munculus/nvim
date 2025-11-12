-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  desc = "Return to last edit position",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  desc = "Create directories when saving",
  callback = function()
    local dir = vim.fn.expand("<afile>:p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  desc = "Highlight when yanking",
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  desc = "Remove trailing whitespace on save",
  callback = function()
    if not vim.fn.expand("%:p"):match("%.md$") then
      vim.cmd([[%s/\s\+$//e]])
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  desc = "Remove line numbers in terminal",
  callback = function()
    vim.wo.number = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "quarto" },
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.wo.wrap = true
    vim.opt_local.shiftwidth = 2
    vim.wo.linebreak = true
    vim.wo.breakindent = true
    vim.wo.showbreak = "|"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "lua", "vim", "r", "rmd" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})
