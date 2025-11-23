---@diagnostic disable: missing-fields
-- vim.cmd.packadd("plenary.nvim")
-- vim.cmd.packadd("harpoon")

local harpoon = require("harpoon")

harpoon:setup({
	settings = {
		save_on_toggle = true,
		sync_on_ui_close = true,
	},
})

-- ------------------------------------------------------------------------
-- Custom Bridge: Harpoon -> Snacks Picker
-- ------------------------------------------------------------------------
local function harpoon_picker()
	local list = harpoon:list()
	local items = {}
	for _, item in ipairs(list.items) do
		table.insert(items, {
			text = item.value,
			file = item.value,
		})
	end
	Snacks.picker.pick({
		source = "harpoon",
		items = items,
		title = "Harpoon",
		layout = "ivy",
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.cmd("edit " .. item.file)
			end
		end,
	})
end

-- ------------------------------------------------------------------------
-- Keymaps
-- ------------------------------------------------------------------------

vim.keymap.set("n", "<leader>a", function()
	harpoon:list():add()
end, { desc = "Harpoon: Add File" })
-- vim.keymap.set("n", "<C-e>", function()
-- 	harpoon.ui:toggle_quick_menu(harpoon:list())
-- end, { desc = "Harpoon: Menu" })

-- Snacks Integration
vim.keymap.set("n", "<C-e>", harpoon_picker, { desc = "Snacks: Harpoon List" })

-- File Navigation (1-4)
vim.keymap.set("n", "<leader>1", function()
	harpoon:list():select(1)
end)
vim.keymap.set("n", "<leader>2", function()
	harpoon:list():select(2)
end)
vim.keymap.set("n", "<leader>3", function()
	harpoon:list():select(3)
end)
vim.keymap.set("n", "<leader>4", function()
	harpoon:list():select(4)
end)

-- Prev/Next
vim.keymap.set("n", "<leader>hp", function()
	harpoon:list():prev()
end, { desc = "Harpoon: Prev" })
vim.keymap.set("n", "<leader>hn", function()
	harpoon:list():next()
end, { desc = "Harpoon: Next" })
