-- lua/plugins/lsp.lua

---------------------------------------------------------------------------
-- lazydev for vim globals
---------------------------------------------------------------------------
require("lazydev").setup({
	library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		{ path = "snacks.nvim", words = { "Snacks" } },
	},
})

---------------------------------------------------------------------------
-- Mason + mason-lspconfig + mason-tool-installer
---------------------------------------------------------------------------

local mason = require("mason")
mason.setup({
	ui = {
		border = "rounded",
	},
})

local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup({
	ensure_installed = {
		-- "lua_ls",
		"basedpyright",
		"ruff",
		-- "jsonls",
		-- "yamlls",
		"rust_analyzer",
	},
	automatic_installation = false,
})

local mason_tool_installer = require("mason-tool-installer")
mason_tool_installer.setup({
	ensure_installed = {
		"stylua",
		"ruff",
		"basedpyright",
	},
	auto_update = false,
	run_on_start = true,
})

---------------------------------------------------------------------------
-- .venv detection for Python
---------------------------------------------------------------------------

local function get_python_path()
	local cwd = vim.fn.getcwd()

	-- Project-local .venv
	local venv_paths = {
		cwd .. "/.venv/bin/python", -- POSIX
		cwd .. "/.venv/Scripts/python.exe", -- Windows
		cwd .. "/.venv/Scripts/python", -- some Windows setups
	}

	for _, path in ipairs(venv_paths) do
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end

	-- Optional: walk up to find a .venv in parent dirs
	local parent = cwd
	while true do
		local next_parent = vim.fn.fnamemodify(parent, ":h")
		if next_parent == parent then
			break
		end
		parent = next_parent
		local parent_venv_paths = {
			parent .. "/.venv/bin/python",
			parent .. "/.venv/Scripts/python.exe",
			parent .. "/.venv/Scripts/python",
		}
		for _, path in ipairs(parent_venv_paths) do
			if vim.fn.filereadable(path) == 1 then
				return path
			end
		end
	end

	-- Fallback: system python
	if vim.fn.executable("python") == 1 then
		return "python"
	elseif vim.fn.executable("python3") == 1 then
		return "python3"
	end

	-- Last resort: nil (basedpyright will use its default)
	return nil
end

local python = get_python_path()

---------------------------------------------------------------------------
-- LspAttach autocmds
--  - Disable Ruff hover (keep basedpyright hover)
--  - Set your buffer-local LSP keymaps
---------------------------------------------------------------------------

-- Disable hover from Ruff so basedpyright owns hover
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = "LSP: Disable hover capability from Ruff",
})

-- User LspAttach: keymaps, etc.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local buf = ev.buf
		local opts_buf = { buffer = buf, silent = true, noremap = true }

		-----------------------------------------------------------------------
		-- Explicit keymaps you requested
		--
		-- We intentionally DO NOT touch any "gr*" mappings, so Neovim 0.12+
		-- lsp-defaults stay intact:
		--   gra / gri / grn / grr / grt / gO / <C-S> / an / in
		-----------------------------------------------------------------------

		-----------------------------------------------------------------------
		-- Customization space: add your own keymaps here as you like
		-----------------------------------------------------------------------

		-- Example: diagnostics float on <leader>d
		-- vim.keymap.set("n", "<leader>d", function()
		--   vim.diagnostic.open_float({ border = "rounded" })
		-- end, opts_buf)

		-- Example: format buffer
		-- vim.keymap.set("n", "<leader>f", function()
		--   vim.lsp.buf.format({ async = true })
		-- end, opts_buf)

		-- Example: tiny-code-action, if you add that plugin
		-- vim.keymap.set({ "n", "x" }, "<leader>ca", function()
		--   require("tiny-code-action").code_action()
		-- end, opts_buf)
	end,
	desc = "User LSP buffer-local keymaps and behavior",
})

---------------------------------------------------------------------------
-- Native vim.lsp.config/vim.lsp.enable definitions
-- This replaces lspconfig.<server>.setup(...)
---------------------------------------------------------------------------

-- Global defaults you might want to share across servers
-- (optional – keep it simple for now)
-- vim.lsp.config["*"] = {
--   capabilities = ...,
-- }

-- Lua
vim.lsp.config.lua_ls = vim.tbl_deep_extend("force", vim.lsp.config.lua_ls or {}, {
	cmd = { "lua-language-server" },
	settings = {
		Lua = {
			hint = {
				enable = false,
			},
		},
	},
})

-- basedpyright with .venv support
vim.lsp.config.basedpyright = vim.tbl_deep_extend("force", vim.lsp.config.basedpyright or {}, {
	settings = {
		python = {
			pythonPath = python,
		},
		basedpyright = {
			disableOrganizeImports = true,
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
				typeCheckingMode = "basic",
				diagnosticSeverityOverrides = {
					reportOptionalMemberAccess = false,
				},
				inlayHints = {
					variableTypes = false,
					functionReturnTypes = false,
					parameterTypes = false,
					callArgumentNames = false,
					genericTypes = false,
				},
			},
		},
	},
})

-- Ruff
vim.lsp.config.ruff = vim.tbl_deep_extend("force", vim.lsp.config.ruff or {}, {
	init_options = {
		settings = {
			lint = { enable = false },
			args = {
				"--line-length=88",
				"--select=E,F,I,B,UP,SIM,ARG",
			},
		},
	},
})

-- JSON
vim.lsp.config.jsonls = vim.tbl_deep_extend("force", vim.lsp.config.jsonls or {}, {})

-- YAML
vim.lsp.config.yamlls = vim.tbl_deep_extend("force", vim.lsp.config.yamlls or {}, {})

-- Rust
vim.lsp.config.rust_analyzer = vim.tbl_deep_extend("force", vim.lsp.config.rust_analyzer or {}, {})

-- Finally, enable the configs so they auto-attach by filetype
vim.lsp.enable("lua_ls")
vim.lsp.enable("basedpyright")
vim.lsp.enable("ruff")
vim.lsp.enable("jsonls")
vim.lsp.enable("yamlls")
vim.lsp.enable("rust_analyzer")
