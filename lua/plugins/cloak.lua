local map = function(mode, key, fn, desc)
  vim.keymap.set(mode, key, fn, { silent = true, noremap = true, desc = desc })
end
require("cloak").setup({
-- enabled = true,
cloak_character = "*",
highlight_group = "Comment",
patterns = {
  {
    file_pattern = { ".env*", "wrangler.toml", ".dev.vars" },
    cloak_pattern = "=.+",
  },
},
})
map("n", "<leader>cl", ":CloakToggle<CR>", "Toggle Cloak")
