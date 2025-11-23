------------------------------------------------------------------------
---theme and theme handlers and overrides
------------------------------------------------------------------------
require("plugins.theme")
require("plugins.theme_loader").setup()
require("plugins.theme_overrides").setup()

------------------------------------------------------------------------
---other plugins
------------------------------------------------------------------------
require("plugins.nvim-notify")
require("plugins.fidget")
require("plugins.snacks")
require("plugins.treesitter")
require("plugins.blink-cmp")
require("plugins.blink-indent")
require("plugins.mini-ai")
require("plugins.mini-surround")
require("plugins.todo-comments")
require("plugins.gitsigns")
require("plugins.smear")
require("plugins.trouble")
require("plugins.formatting")
require("plugins.cloak")

require("plugins.lsp")
