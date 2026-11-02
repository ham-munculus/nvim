require("config.remote_clipboard").setup()
local vo = vim.opt
vo.path:append("**")

vo.termguicolors = true
vim.g.mapleader = " "

--display
vo.number = true
vo.relativenumber = true
vo.cursorline = true
vo.scrolloff = 10
vo.sidescrolloff = 8
vo.mouse = "a"
vo.showmode = true
vo.signcolumn = "yes"
vo.showmatch = true
vo.winblend = 0
vo.winborder = "rounded"
vo.confirm = true
vim.g.indent_guide = false

-- indentation
vo.tabstop = 4
vo.shiftwidth = 4
vo.expandtab = true
vo.autoindent = true
vo.smartindent = true

--search
-- vo.clipboard:append("unnamedplus")
vo.ignorecase = true
vo.smartcase = true
vo.incsearch = true
vo.inccommand = "split"

--file handling
vo.backup = false
vo.writebackup = false
vo.swapfile = false
vo.undofile = true
vo.undodir = vim.fn.expand("~/.nvim/undodir")

--performance
vo.redrawtime = 10000
vo.maxmempattern = 20000
vo.diffopt:append("linematch:60")

if vim.fn.has("wsl") == 1 then
	vim.g.clipboard = {
		name = "wsl-wl-clipboard",
		copy = {
			["+"] = { "wl-copy", "--type", "text/plain" },
			["*"] = { "wl-copy", "--type", "text/plain" },
		},
		paste = {
			["+"] = { "sh", "-c", "wl-paste --no-newline | tr -d '\\r'" },
			["*"] = { "sh", "-c", "wl-paste --no-newline | tr -d '\\r'" },
		},
		cache_enabled = 0,
	}

	vim.opt.clipboard = "unnamedplus"
end
