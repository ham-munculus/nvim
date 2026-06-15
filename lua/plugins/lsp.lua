-- lua/plugins/lsp.lua

local function get_python_path()
	local cwd = vim.fn.getcwd()

	local candidates = {
		cwd .. "/.venv/Scripts/python.exe",
		cwd .. "/.venv/Scripts/python",
		cwd .. "/.venv/bin/python",
	}

	for _, path in ipairs(candidates) do
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end

	if vim.fn.executable("python") == 1 then
		return "python"
	end

	if vim.fn.executable("python3") == 1 then
		return "python3"
	end
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason").setup()

require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"rust_analyzer",
		"gopls",
		"vtsls",
		"tailwindcss",
		"basedpyright",
		"ruff",
	},
})

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "if_many",
	},
})

vim.lsp.config("*", {
	capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim", "Snacks", "augroup" },
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					vim.fn.stdpath("config"),
				},
			},
			telemetry = {
				enable = false,
			},
		},
	},
})

vim.lsp.config("basedpyright", {
	settings = {
		python = {
			pythonPath = get_python_path(),
		},
		basedpyright = {
			disableOrganizeImports = true,
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
				typeCheckingMode = "basic",
			},
		},
	},
})

vim.lsp.config("ruff", {
	init_options = {
		settings = {
			organizeImports = true,
		},
	},
})

vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			check = {
				command = "clippy",
			},
		},
	},
})

vim.lsp.config("tailwindcss", {
	filetypes = {
		"html",
		"css",
		"scss",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
		"svelte",
		"heex",
	},
})

vim.lsp.enable({
	"lua_ls",
	"rust_analyzer",
	"gopls",
	"vtsls",
	"tailwindcss",
	"basedpyright",
	"ruff",
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)

		if client and client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end

		local opts = { buffer = ev.buf }

		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
	end,
})
