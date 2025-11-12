-- any labeled lazy default are configured by default by lazyvim.
-- otherwise, they are archived configs that need their own plugin file
-- and enabled = true to be enabled
return {
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },
  {
    "folke/noice.nvim",
    enabled = false,
  },
  {
    "nvim-mini/mini.indentscope",
    enabled = false,
    event = "VeryLazy",
    config = function()
      require("mini.indentscope").setup({
        symbol = "│",
        draw = {
          delay = 0,
          animation = require("mini.indentscope").gen_animation.none(),
        },
      })
    end,
  },
}
