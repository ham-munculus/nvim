-- lua/plugins/snacks.lua
require("snacks").setup({
	picker = {
		hidden = true, -- Show hidden files in picker
		ignored = true, -- show git ignored
		sources = {
			file = {
				hidden = true, -- Show hidden files in file picker
				ignored = true, -- show git ignored
				exclude = { ".venv", ".git", "**/.git/*", "**/.venv/*" },
			},
		},
		matcher = {
			frecency = true,
		},
	},
	explorer = {
		replace_netrw = false,
		hidden = true, -- show hidden
		ignored = false, -- show git ignored
		layout = { preview = true },
	},
	zen = {
		center = true,
		show = {
			statusline = false,
		},
		backdrop = {
			enabled = true,
		},
		win = {
			backdrop = {
				blend = 20,
			},
		},
	},
})
