require("conform").setup({
	format_on_save = {
		timeout_ms = 5000,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff" },
		rust = { "rustfmt" },
		json = { "prettierd", "prettier", "jq" },
		-- For JSON with comments (tsconfig.json, etc.)
		jsonc = { "prettierd", "prettier" },
	},
})

require("nvim-autopairs").setup()
