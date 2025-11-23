-- lua/plugins/theme_overrides.lua

local M = {}

function M.setup()
	local cs = vim.g.colors_name

	---------------------------------------------------------------------------
	-- Everforest: hard + transparent
	---------------------------------------------------------------------------
	if cs == "everforest" then
		local ok, everforest = pcall(require, "everforest")
		if ok and everforest.setup then
			everforest.setup({
				background = "hard", -- "hard", "medium", "soft"
				transparent_background_level = 2, -- 0–2, higher = more transparent
			})
		else
			-- Fallback globals; harmless if unused by this fork
			vim.g.everforest_background = "hard"
			vim.g.everforest_transparent_background = 3
		end

		-- Reapply Everforest with updated settings
		pcall(vim.cmd.colorscheme, "everforest")
		cs = vim.g.colors_name
	end

	---------------------------------------------------------------------------
	-- Tokyonight: transparent background
	---------------------------------------------------------------------------
	if cs and cs:match("^tokyonight") then
		local ok, tokyonight = pcall(require, "tokyonight")
		if ok and tokyonight.setup then
			tokyonight.setup({
				-- style = "night", -- optional: force variant if desired
				transparent = true,
				styles = {
					sidebars = "transparent",
					floats = "transparent",
				},
			})
		else
			vim.g.tokyonight_transparent = true
		end

		-- Reapply the exact variant Omarchy picked
		pcall(vim.cmd.colorscheme, cs)
	end

	---------------------------------------------------------------------------
	-- Catppuccin Mocha Dark: transparent background
	---------------------------------------------------------------------------
	if cs and cs:match("^catppuccin") then
		local ok, catppuccin = pcall(require, "catppuccin")
		if ok and catppuccin.setup then
			catppuccin.setup({
				flavour = "mocha", -- ensure we’re on mocha
				transparent_background = true,
				float = {
					transparent = true,
					solid = false,
				},
				-- optional extra tweaks:
				-- term_colors = false,
				-- dim_inactive = { enabled = false },
			})
		else
			-- fallback globals for older versions; mostly safe no-ops now
			vim.g.catppuccin_flavour = "mocha"
			vim.g.catppuccin_transparent_background = true
		end

		-- reapply whatever exact scheme Omarchy picked (e.g. "catppuccin-mocha")
		pcall(vim.cmd.colorscheme, cs)
		cs = vim.g.colors_name
	end

	---------------------------------------------------------------------------
	-- Temerald (example: uses Poimandres underneath)
	---------------------------------------------------------------------------
	if cs == "poimandres" then
		local ok, poimandres = pcall(require, "poimandres")
		if ok and poimandres.setup then
			poimandres.setup({
				-- Poimandres uses transparent = true to remove bg
				disable_background = true, -- or transparent = true, depending on plugin
				-- check the plugin README for the exact option name
			})
		else
			-- If the plugin exposes only globals, set them here
			-- (just an example; check plugin docs)
			vim.g.poimandres_disable_background = true
		end

		-- Reapply colorscheme with transparent background
		pcall(vim.cmd.colorscheme, "poimandres")
		cs = vim.g.colors_name
	end

	---------------------------------------------------------------------------
	-- Optional: enforce transparent backgrounds globally
	---------------------------------------------------------------------------
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("TransparentBackground", { clear = true }),
		callback = function()
			vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
			vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
			vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
			vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
			vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
			-- Uncomment if desired:
			-- vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
			-- vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
			-- vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
		end,
	})
end

return M
