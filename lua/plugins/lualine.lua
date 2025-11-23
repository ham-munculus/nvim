-- Define icons locally (extracted from LazyVim defaults)
local icons = {
	diagnostics = {
		Error = " ",
		Warn = " ",
		Hint = " ",
		Info = " ",
	},
	git = {
		added = " ",
		modified = " ",
		removed = " ",
	},
}

require("lualine").setup({
	options = {
		theme = "auto", -- Respects your current colorscheme
		globalstatus = true, -- Single statusline at bottom of neovim
		disabled_filetypes = { statusline = { "dashboard", "alpha", "snacks_dashboard" } },
		component_separators = "|",
		section_separators = "",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch" },

		lualine_c = {
			-- Diagnostics
			{
				"diagnostics",
				symbols = {
					error = icons.diagnostics.Error,
					warn = icons.diagnostics.Warn,
					info = icons.diagnostics.Info,
					hint = icons.diagnostics.Hint,
				},
			},
			-- Filetype icon
			{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
			-- Filename (Relative Path)
			{ "filename", path = 1 },
		},
		lualine_x = {
			-- Snacks Profiler (if you use it)
			{
				function()
					return Snacks.profiler.status()
				end,
				cond = function()
					return Snacks and Snacks.profiler
				end,
			},
			-- Git Diff (Uses Gitsigns logic)
			{
				"diff",
				symbols = {
					added = icons.git.added,
					modified = icons.git.modified,
					removed = icons.git.removed,
				},
				source = function()
					local gitsigns = vim.b.gitsigns_status_dict
					if gitsigns then
						return {
							added = gitsigns.added,
							modified = gitsigns.changed,
							removed = gitsigns.removed,
						}
					end
				end,
			},
		},
		lualine_y = {
			{ "progress", separator = " ", padding = { left = 1, right = 0 } },
			{ "location", padding = { left = 0, right = 1 } },
		},
		lualine_z = {
			-- Time
			function()
				return " " .. os.date("%R")
			end,
		},
	},
	extensions = { "quickfix", "man" },
})
