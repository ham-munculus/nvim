local surround = require("mini.surround")

surround.setup({
	mappings = {
		add = "sa", -- Add surrounding in Normal and Visual modes
		delete = "ds", -- Delete surrounding
		find = "sf", -- Find surrounding (to the right)
		find_left = "sF", -- Find surrounding (to the left)
		highlight = "sh", -- Highlight surrounding
		replace = "cs", -- Replace surrounding

		suffix_last = "l", -- Suffix to search with "prev" method
		suffix_next = "n", -- Suffix to search with "next" method
	},
})
