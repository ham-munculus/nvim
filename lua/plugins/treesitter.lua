require("nvim-treesitter.configs").setup({
	modules = {},
	sync_install = true,
	ensure_installed = {
		"python",
		"lua",
		"rust",
	},
	ignore_install = {},
	auto_install = true,
	highlight = {
		enable = true,
	},
})
