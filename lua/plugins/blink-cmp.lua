require("blink-cmp").setup({
  keymap = {
    preset = "default",
    ["<CR>"] = { "fallback" }, -- Disable accept, only use normal Enter
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = { implementation = "prefer_rust" },
  completion = { documentation = { auto_show = false } },
})
