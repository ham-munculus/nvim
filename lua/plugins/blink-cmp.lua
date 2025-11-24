require("blink-cmp").setup({
	keymap = {
		preset = "default",
		["<CR>"] = { "fallback" }, -- Disable accept, only use normal Enter
	},
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
	fuzzy = { implementation = "prefer_rust" },
	completion = { documentation = { auto_show = false } },
})
-- return {
--   "saghen/blink.cmp",
--   dependencies = { { "rafamadriz/friendly-snippets" } },
--   version = "1.*",
--   ---@module 'blink.cmp'
--   ---@type blink.cmp.Config
--   opts = {
--     keymap = {
--       preset = "default",
--       ["<CR>"] = { "fallback" }, -- Disable accept, only use normal Enter
--     },
--     sources = {
--       default = { "lsp", "path", "snippets", "buffer" },
--     },
--     fuzzy = { implementation = "prefer_rust_with_warning" },
--     completion = { documentation = { auto_show = false } },
--   },
--   opts_extend = { "sources.default" },
-- }
