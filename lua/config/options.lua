-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- =====================
-- BASIC VIM SETTINGS
-- =====================
-- vim.cmd.colorscheme("unokai")

-- Transparency settings
-- local transparent_groups = {
--   "Normal",
--   "NormalNC",
--   "NormalFloat",
--   "EndOfBuffer",
--   "WinBar",
--   "WinBarNC",
--   "Statusline",
--   "StatuslineNC",
-- }
-- for _, group in ipairs(transparent_groups) do
--   vim.api.nvim_set_hl(0, group, { bg = "none" })
-- end

vim.opt.path:append("**")

-- Floating window styling
-- vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none", fg = "#b9f3fb" })
-- vim.api.nvim_set_hl(0, "FloatTitle", { bg = "none", fg = "#FF8200" })

vim.opt.termguicolors = true
vim.g.mapleader = " "
-- vim.g.maplocalleader = " "

-- Display
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.signcolumn = "yes"
vim.opt.showmatch = true
vim.opt.winblend = 0
vim.opt.confirm = true

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

-- Clipboard & splits
-- vim.opt.clipboard:append("unnamedplus")
vim.opt.splitbelow = true
vim.opt.splitright = true

-- File handling
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
-- vim.opt.updatetime = 300
-- vim.opt.timeoutlen = 500
-- vim.opt.ttimeoutlen = 0
vim.opt.autoread = true
vim.opt.autowrite = false

-- Performance
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000
vim.opt.diffopt:append("linematch:60")
