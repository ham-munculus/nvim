require("plugins.theme")

require("plugins.lsp")
require("plugins.completion")
require("plugins.fff")
require("plugins.nvim-notify")
require("plugins.fidget")
require("plugins.mini-surround")
require("plugins.mini-ai")
require("plugins.todo-comments")
-- require("plugins.gitsigns")
require("plugins.smear")
-- Use dofile here because this config file also calls require("trouble") for the
-- plugin itself; LuaLS can otherwise report that the same file is required under
-- different module names.
dofile(vim.fn.stdpath("config") .. "/lua/plugins/trouble.lua")
require("plugins.formatting")
require("plugins.cloak")
require("plugins.flash")
require("plugins.lualine")
require("plugins.snacks")
require("plugins.treesitter")
require("plugins.render-markdown")
require("plugins._99")
