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

map("n", "<leader>pu", ":lua vim.pack.update()<CR>", "Update plugins")

map("n", "<c-s-3>", function()
	local number = vim.wo.number
	local relativenumber = vim.wo.relativenumber

	if number or relativenumber then
		vim.wo.number = false
		vim.wo.relativenumber = false
	else
		vim.wo.number = true
		vim.wo.relativenumber = true
	end
end, "Toggle relative and absolute numbers")

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
map("n", "<leader>ii", function()
	indent.enable(not indent.is_enabled())
end, "Toggle indent guides")

-- Snacks picker keymaps
require("snacks")
map("n", "<leader>ff", function()
	Snacks.picker.smart()
end, "Smart Find files")
map("n", "<leader>/", function()
	Snacks.picker.grep({ layout = "ivy" })
end, "Multi-grep")
map("n", "<leader>n", function()
	Snacks.picker.notifications({ layout = "ivy" })
end, "Notifications")
map("n", "<leader>f;", function()
	Snacks.picker.command_history({ layout = "ivy" })
end, "Command History")
map("n", "<leader>E", function()
	Snacks.picker.explorer()
end, "Explorer")
map("n", "<leader>fg", function()
	Snacks.picker.git_branches({ layout = "ivy" })
end, "Git Branches")
map("n", "<leader>fx", function()
	Snacks.picker.diagnostics({ layout = "ivy" })
end, "Diagnostics")
map("n", "<leader>fh", function()
	Snacks.picker.help()
end, "Help Documentation")
map("n", "<leader>fk", function()
	Snacks.picker.keymaps({ layout = "ivy" })
end, "Keymaps")
map("n", "<leader>fq", function()
	Snacks.picker.qflist({ layout = "ivy" })
end, "Quick Fix List")
map("n", "<leader>fc", function()
	Snacks.picker.colorschemes({ layout = "ivy" })
end, "Colorscheme")
map("n", "gd", function()
	Snacks.picker.lsp_definitions()
end, "Goto Definition")
map("n", "gD", function()
	Snacks.picker.lsp_declarations()
end, "Goto Declaration")
-- map("n", "grr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" )
map("n", "gI", function()
	Snacks.picker.lsp_implementations()
end, "Goto Implementation")
map("n", "gy", function()
	Snacks.picker.lsp_type_definitions()
end, "Goto T[y]pe Definition")

map("n", "<leader>z", ":lua Snacks.zen()<cr>", "Enable zen mode")

-- trouble keymaps
map("n", "<leader>xx", ":Trouble diagnostics toggle<cr>", "Diagnostics (trouble)")

map("n", "<leader>e", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.bo[buf].filetype
		local config = vim.api.nvim_win_get_config(win)

		if ft == "netrw" and config.relative == "" then
			vim.api.nvim_win_close(win, true)
			return
		end
	end

	local dir = vim.fn.expand("%:p:h")
	if dir == "" then
		dir = vim.fn.getcwd()
	end

	vim.cmd.Lexplore(dir)
end, "Left hand netrw Explorer")
