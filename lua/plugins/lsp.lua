return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {},
        -- basedpyright = {
        --   settings = {
        --     basedpyright = {
        --       analysis = {
        --         typeCheckingMode = "standard",
        --       },
        --     },
        --   },
        -- },
        pyright = {},
        ruff = {},
        jsonls = {},
        yamlls = {},
        rust_analyzer = {},
      },
    },
    capabilities = {},
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua", -- formatter only
        -- other tools that aren't LSP servers
      },
    },
  },
}
