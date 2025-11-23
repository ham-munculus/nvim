require("todo-comments").setup({ signs = true })

vim.keymap.set("n", "<leader>ft", function()
	local curr_path = vim.fn.expand("%:p")
	Snacks.picker.todo_comments({ ---@diagnostic disable-line: undefined-field
		transform = function(item)
			local item_path = vim.fn.fnamemodify(item.cwd .. "/" .. item.file, ":p")
			return item_path == curr_path
		end,
		layout = "ivy",
	})
end, { desc = "Todo (Current File)" })
