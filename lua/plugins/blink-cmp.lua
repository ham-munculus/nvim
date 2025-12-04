require("blink-cmp").setup({
	keymap = {
		preset = "default",
		["<CR>"] = { "fallback" }, -- Disable accept, only use normal Enter
	},
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
	fuzzy = {
    implementation = "prefer_rust" ,
    prebuilt_binaries = {
      download = false,
      ignore_version_mismatch = true,
    },
  },
	completion = { documentation = { auto_show = false } },
})
