-- lua/plugins/snacks.lua
require("snacks").setup({

  picker = {
    -- layout =  "ivy" , -- uncomment for global layout style
    hidden = true,
    ignored = true,
    sources = {
      file = {
        hidden = true,
        ignored = true,
      },
    },
    matcher = {
      frecency = true,
    },
  },
})

-- return {
--   {
--     "folke/snacks.nvim",
--     opts = {
--       explorer = {
--         enabled = false,
--       },
--       indent = {
--         enabled = false,
--       },
--       picker = {
--         hidden = true,
--         ignored = true,
--         sources = {
--           file = {
--             hidden = true,
--             ignored = true,
--           },
--         },
--       },
--     },
--   },
-- }
