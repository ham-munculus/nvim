local map = function(mode, key, fn, desc)
	vim.keymap.set(mode, key, fn, { silent = true, noremap = true, desc = desc })
end

local floating = require("utils.floating-windows")

-- Commands
-- vim.api.nvim_create_user_command("Floaterminal", floating.toggle_floating_terminal, {})
vim.api.nvim_create_user_command("BottomTerm", floating.toggle_bottom_terminal, {})
vim.api.nvim_create_user_command("Messages", floating.show_messages, {})

-- UI
map("n", "<leader>t3", function()
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

map("n", "<leader>m", floating.show_messages, "Show messages")
map("n", "<leader>wp", "<cmd>setlocal wrap<CR>", "Enable text wrap")

-- Explorer
-- map("n", "<leader>e", ":Explore<cr>", "toggle netrw left split explorer")
map("n", "<leader>e", function()
	Snacks.explorer({
		reveal = true,
	})
end, "toggle netrw left split explorer")

-- Insert mode
map("i", "jk", "<ESC>", "exit insert mode")

-- Visual / select mode
map("x", "p", [["_dP"]], "Paste without losing yanked selection")

-- Visual mode
map("v", "J", ":m '>+1<CR>gv=gv", "move selection down")
map("v", "K", ":m '<-2<CR>gv=gv", "move selection up")
map("v", ">", ">gv", "indent keep selection")
map("v", "<", "<gv", "dedent keep selection")

-- Movement
map("n", "<C-d>", "<C-d>zz", "scroll down centered")
map("n", "<C-u>", "<C-u>zz", "scroll up centered")
map("n", "G", "Gzz", "center after jumpto end")

-- vim.keymap.set("n", "j", function()
-- 	return (vim.v.count == 0 and "gj" or "j") .. "zz"
-- end, { expr = true, silent = true, desc = "Down (wrap-aware, centered)" })
--
-- vim.keymap.set("n", "k", function()
-- 	return (vim.v.count == 0 and "gk" or "k") .. "zz"
-- end, { expr = true, silent = true, desc = "Up (wrap-aware, centered)" })

-- Editing
map("n", "<leader>S", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], "replace word under cursor")
map("n", "<leader>o", "o<ESC>", "new line under")
map("n", "<leader>O", "O<ESC>", "new line above")

-- Execute / source
map("n", "<space><space>x", "<cmd>source %<CR>", "source current file")
map("n", "<space><space>c", "<cmd>source ~/AppData/Local/nvim/init.lua<CR>", "source init.lua")

-- Tabs
map("n", "<leader>to", "<cmd>tabnew<CR>", "Open new tab")
map("n", "<leader>tw", "<cmd>tabclose<CR>", "Close tab")
map("n", "<leader>tn", "<cmd>tabn<CR>", "Next tab")
map("n", "<leader>tp", "<cmd>tabp<CR>", "Previous tab")
-- map("n", "<leader>tf", "<cmd>tabnew %<CR>", "Open buffer in new tab")

-- Terminal
map({ "n", "t", "v" }, "<leader>t<space>", floating.toggle_floating_terminal, "toggle floating terminal")
map({ "n", "t", "v" }, "<leader>tt", floating.toggle_bottom_terminal, "toggle bottom terminal")
map({ "n", "i", "t", "v" }, "<C-M-b>", floating.toggle_right_terminal, "toggle right split opencode")
map("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")

-- Marks
map("n", "<leader>xm", function()
	vim.cmd("delmarks!")
	print("all marks deleted")
end, "delete all marks")

-- Todo
map("n", "<leader>ng", "<cmd>TodoGlobal<CR>", "open global todo note")
map("n", "<leader>nl", "<cmd>TodoLocal<CR>", "open local todo note")
-- Indent guides
-- local indent = require("blink.indent")
-- map("n", "<leader>ii", function()
-- 	indent.enable(not indent.is_enabled())
-- end, "Toggle indent guides")

-- GitHub via Snacks.gh
map("n", "<leader>gi", function()
	Snacks.picker.gh_issue()
end, "GitHub Issues (open)")

map("n", "<leader>gI", function()
	Snacks.picker.gh_issue({ state = "all" })
end, "GitHub Issues (all)")

map("n", "<leader>gp", function()
	Snacks.picker.gh_pr()
end, "GitHub Pull Requests (open)")

map("n", "<leader>gP", function()
	Snacks.picker.gh_pr({ state = "all" })
end, "GitHub Pull Requests (all)")

-- Lazygit via Snacks
map({ "n", "t", "i", "v" }, "<leader>gg", "<CMD>lua Snacks.lazygit.open()<CR>", "Toggle Open LazyGit")

-- Diagnostics
map("n", "<leader>d", ":lua vim.diagnostic.open_float()<CR>", "toggle diagnostic floating window")
map("n", "<leader>fd", function()
	Snacks.picker.diagnostics()
end, "Find diagnostics")
map("n", "<leader>fD", function()
	Snacks.picker.diagnostics_buffer()
end, "Find buffer diagnostics")

-- Keymap finder: list = mode, key, description; the preview pane gets a winbar header with the
-- full description and where the map is defined (the preview itself shows the code/mapping).
local function keymap_format(item)
	local k = item.item
	local desc = (k.desc and k.desc ~= "") and k.desc or (k.rhs and k.rhs ~= "" and k.rhs) or "callback"
	return {
		{ k.mode, "SnacksPickerKeymapMode" },
		{ " " },
		{ Snacks.picker.util.align(Snacks.util.normkey(k.lhs), 15), "SnacksPickerKeymapLhs" },
		{ " " },
		{ desc, (k.desc and k.desc ~= "") and "Title" or "Comment" },
	}
end

local function keymap_preview(ctx)
	Snacks.picker.preview.preview(ctx)
	local k = ctx.item.item
	local where = ctx.item.file and (vim.fn.fnamemodify(ctx.item.file, ":t") .. (ctx.item.pos and (":" .. ctx.item.pos[1]) or ""))
		or "vimscript / command"
	local function esc(t) return (tostring(t):gsub("%%", "%%%%")) end
	ctx.preview:wo({
		winbar = ("%%#Title# %s %%*%%=%%#Comment# %s "):format(esc((k.desc and k.desc ~= "") and k.desc or "(no description)"), esc(where)),
	})
end

map("n", "<leader>fk", function()
	Snacks.picker.keymaps({ format = keymap_format, preview = keymap_preview })
end, "Find keymaps")

-- Trouble
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)")
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer Diagnostics (Trouble)")

map("n", "<leader>xn", function()
	require("trouble").next({ mode = "diagnostics", skip_groups = true, jump = true })
end, "Next diagnostic (Trouble)")

map("n", "<leader>xp", function()
	require("trouble").prev({ mode = "diagnostics", skip_groups = true, jump = true })
end, "Previous diagnostic (Trouble)")

map("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", "Symbols (Trouble)")
map(
	"n",
	"<leader>cl",
	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
	"LSP Definitions / references / ... (Trouble)"
)
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Location List (Trouble)")
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", "Quickfix List (Trouble)")

-- Smart Splits / WezTerm
--
local ok, splits = pcall(require, "smart-splits")
if ok then
	map("n", "<A-h>", splits.resize_left, "Resize split left")
	map("n", "<A-j>", splits.resize_down, "Resize split down")
	map("n", "<A-k>", splits.resize_up, "Resize split up")
	map("n", "<A-l>", splits.resize_right, "Resize split right")

	map("n", "<C-h>", splits.move_cursor_left, "Move to left pane")
	map("n", "<C-j>", splits.move_cursor_down, "Move to lower pane")
	map("n", "<C-k>", splits.move_cursor_up, "Move to upper pane")
	map("n", "<C-l>", splits.move_cursor_right, "Move to right pane")
	map("n", "<C-\\>", splits.move_cursor_previous, "Move to previous pane")

	map("n", "<leader><leader>h", splits.swap_buf_left, "Swap buffer left")
	map("n", "<leader><leader>j", splits.swap_buf_down, "Swap buffer down")
	map("n", "<leader><leader>k", splits.swap_buf_up, "Swap buffer up")
	map("n", "<leader><leader>l", splits.swap_buf_right, "Swap buffer right")
end
