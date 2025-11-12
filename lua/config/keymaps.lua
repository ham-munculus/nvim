-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = function(mode, key, fn, desc)
  vim.keymap.set(mode, key, fn, { silent = true, noremap = true, desc = desc })
end

local floating = require("utils.floating-windows")
-- vim.api.nvim_create_user_command("Floaterminal", floating.toggle_floating_terminal, {})
vim.api.nvim_create_user_command("BottomTerm", floating.toggle_bottom_terminal, {})
vim.api.nvim_create_user_command("Messages", floating.show_messages, {})

-- map("n", "<leader>\\", floating.toggle_floating_terminal, "toggle floating terminal")
-- map("i", "<leader>\\", floating.toggle_floating_terminal, "toggle floating terminal")
-- map("t", "<leader>\\", floating.toggle_floating_terminal, "toggle floating terminal")
map("n", "<leader>tt", floating.toggle_bottom_terminal, "toggle bottom terminal")
map("i", "<leader>tt", floating.toggle_bottom_terminal, "toggle bottom terminal")
map("t", "<leader>tt", floating.toggle_bottom_terminal, "toggle bottom terminal")
map("n", "<leader>n", floating.show_messages, "Show messages")

-- Insert mode
map("i", "jk", "<ESC>", "exit insert mode")

-- Normal mode
map("n", "<C-d>", "<C-d>zz", "scroll down centered")
map("n", "<C-u>", "<C-u>zz", "scroll up centered")
-- map("n", "j", "jzz", "move down centered")
-- map("n", "k", "kzz", "move up centered")
vim.keymap.set("n", "j", function()
  return (vim.v.count == 0 and "gj" or "j") .. "zz"
end, { expr = true, silent = true, desc = "Down (wrap-aware, centered)" })

vim.keymap.set("n", "k", function()
  return (vim.v.count == 0 and "gk" or "k") .. "zz"
end, { expr = true, silent = true, desc = "Up (wrap-aware, centered)" })

-- Window navigation
-- map("n", "<C-S-h>", "<C-w><C-h>", "Move focus to left")
-- map("n", "<C-S-l>", "<C-w><C-l>", "Move focus to right")
-- map("n", "<C-S-j>", "<C-w><C-j>", "Move focus to bottom")
-- map("n", "<C-S-k>", "<C-w><C-k>", "Move focus to top")

-- Visual mode
map("v", "J", ":m '>+1<CR>gv=gv", "move selection down")
map("v", "K", ":m '<-2<CR>gv=gv", "move selection up")
map("v", ">", ">gv", "indent keep selection")
map("v", "<", "<gv", "dedent keep selection")

-- Lines
map("n", "<leader>o", "o<ESC>", "new line under")
map("n", "<leader>O", "O<ESC>", "new line above")
map("n", "G", "Gzz", "center after jumpto end")

-- Execute
map("n", "<space><space>x", "<cmd>source %<CR>", "source current file")
map("n", "<space><space>c", "<cmd>source ~/.config/nvim/init.lua<CR>", "source init.lua")

-- Search
-- map("n", "<Esc>", "<cmd>nohlsearch<CR>", "clear search highlight")

-- Splits
-- map("n", "<leader>sv", "<C-w>v", "Split vertically")
-- map("n", "<leader>sh", "<C-w>s", "Split horizontally")
-- map("n", "<leader>se", "<C-w>=", "Equal split size")
-- map("n", "<leader>sw", "<cmd>close<CR>", "Close split")

-- Resize
-- map("n", "<S-Up>", "<cmd>resize +2<CR>", "Resize up")
-- map("n", "<S-Down>", "<cmd>resize -2<CR>", "Resize down")
-- map("n", "<S-Left>", "<cmd>vertical resize -2<CR>", "Resize left")
-- map("n", "<S-Right>", "<cmd>vertical resize +2<CR>", "Resize right")

-- Tabs
map("n", "<leader>to", "<cmd>tabnew<CR>", "Open new tab")
map("n", "<leader>tw", "<cmd>tabclose<CR>", "Close tab")
map("n", "<leader>tn", "<cmd>tabn<CR>", "Next tab")
map("n", "<leader>tp", "<cmd>tabp<CR>", "Previous tab")
map("n", "<leader>tf", "<cmd>tabnew %<CR>", "Open buffer in new tab")

-- Text wrapping
map("n", "<leader>wp", "<cmd>setlocal wrap<CR>", "Enable text wrap")

-- Terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")

-- File explorer
-- map("n", "\\", ":Explore<CR>", "Open file explorer") -- disabled for localleader reasons
-- map("n", "<leader>e", ":Explore<CR>", "Open file explorer")

-- Delete marks
map("n", "<leader>dm", function()
  vim.cmd("delmarks!")
  print("all marks deleted")
end, "delete all marks")

local indent = require("blink.indent")
map("n", "<leader>di", function()
  indent.enable(not indent.is_enabled())
end, "Toggle indent guides")
