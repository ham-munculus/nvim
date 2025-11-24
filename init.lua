vim.pack.add({
	-- lsp & completion
	{ src = "https://github.com/Saghen/blink.cmp" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
	{ src = "https://github.com/folke/lazydev.nvim" },
	{ src = "https://github.com/j-hui/fidget.nvim.git" },

	-- ui
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },

	-- formatting & editor
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/folke/trouble.nvim" },
	{ src = "https://github.com/artemave/workspace-diagnostics.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/windwp/nvim-autopairs" },
	{ src = "https://github.com/nvim-mini/mini.nvim" },

	-- snacks
	{ src = "https://github.com/folke/snacks.nvim.git" },

	-- misc plugins
	{ src = "https://github.com/rcarriga/nvim-notify.git" },
	{ src = "https://github.com/laytan/cloak.nvim.git" },
	{ src = "https://github.com/sphamba/smear-cursor.nvim.git" },
	{ src = "https://github.com/saghen/blink.indent.git" },
	{ src = "https://github.com/folke/flash.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim.git" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim.git" },
	{ src = "https://github.com/folke/todo-comments.nvim.git" },

	-- colorschemes from omarchy themes
	{ src = "https://github.com/everviolet/nvim.git", name = "evergarden" }, -- Evergarden
	{ src = "https://github.com/bjarneo/ash.nvim.git", name = "ash" }, -- Ash
	{ src = "https://github.com/rose-pine/neovim.git", name = "rose-pine" }, -- Rose Pine
	{ src = "https://github.com/neanias/everforest-nvim.git", name = "everforest", opts = { background = "hard" } }, -- Everforest
	{ src = "https://github.com/folke/tokyonight.nvim.git", name = "tokyonight" }, -- Tokyo night
	{ src = "https://github.com/catppuccin/nvim.git", name = "catppuccin" }, -- Catppuccin
	{ src = "https://github.com/rebelot/kanagawa.nvim.git", name = "kanagawa" }, -- Kanagawa
	{ src = "https://github.com/bjarneo/ethereal.nvim.git", name = "ethereal" }, -- Ethereal
	{ src = "https://github.com/tahayvr/matteblack.nvim.git", name = "matteblack" }, -- Matte Black
	{ src = "https://github.com/ellisonleao/gruvbox.nvim.git", name = "gruvbox" }, -- Gruvbox
	{ src = "https://github.com/bjarneo/hackerman.nvim.git", name = "hackerman" }, -- Hackerman
	{ src = "https://github.com/EdenEast/nightfox.nvim.git", name = "nordfox" }, -- Nord
	{ src = "https://github.com/ribru17/bamboo.nvim.git", name = "bamboo" }, -- Osaka-jade
	{ src = "https://github.com/olivercederborg/poimandres.nvim.git", name = "poimandres" }, -- Temerald
	{ src = "https://github.com/catppuccin/nvim.git", name = "catppuccin-dark" }, -- Catppuccin dark
})
require("config.init")
require("plugins.init")

-- test change
