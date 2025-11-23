require("plugins.theme")
require("plugins.theme_loader").setup()
require("plugins.theme_overrides").setup()
-- -- If Omarchy chose everforest, configure it for hard+transparent and reapply
-- if vim.g.colors_name == "everforest" then
-- 	local ok, everforest = pcall(require, "everforest")
-- 	if ok and everforest.setup then
-- 		everforest.setup({
-- 			background = "hard", -- hard contrast
-- 			transparent_background_level = 2, -- 1‑3: higher = more transparent
-- 			italics = true,
-- 			disable_italics = false,
-- 			ui_contrast = "high",
-- 		})
-- 	else
-- 		-- Fallback for older/global-style configs (harmless if unused)
-- 		vim.g.everforest_background = "hard"
-- 		vim.g.everforest_transparent_background = 3
-- 	end
--
-- 	-- Reapply the colorscheme with the new settings
-- 	pcall(vim.cmd.colorscheme, "everforest")
-- end
-- -- Tokyonight: fully transparent
-- do
-- 	local cs = vim.g.colors_name
-- 	-- Omarchy may use variants like "tokyonight", "tokyonight-night", etc.
-- 	if cs and cs:match("^tokyonight") then
-- 		local ok, tokyonight = pcall(require, "tokyonight")
-- 		if ok and tokyonight.setup then
-- 			tokyonight.setup({
-- 				-- style = "night", -- optional, only if you want to force one variant
-- 				transparent = true,
-- 				styles = {
-- 					sidebars = "transparent",
-- 					floats = "transparent",
-- 				},
-- 			})
-- 		else
-- 			-- Legacy globals, mostly for older versions; harmless here
-- 			-- vim.g.tokyonight_style = "night"
-- 			vim.g.tokyonight_transparent = true
-- 		end
--
-- 		-- Reapply the exact variant Omarchy picked
-- 		pcall(vim.cmd.colorscheme, cs)
-- 	end
-- end

require("plugins.nvim-notify")
require("plugins.fidget")
require("plugins.snacks")
require("plugins.treesitter")
require("plugins.blink-cmp")
require("plugins.blink-indent")
require("plugins.mini-ai")
require("plugins.mini-surround")
require("plugins.harpoon")
require("plugins.todo-comments")
require("plugins.gitsigns")
require("plugins.smear")
require("plugins.trouble")
require("plugins.formatting")
require("plugins.cloak")

require("plugins.lsp")
