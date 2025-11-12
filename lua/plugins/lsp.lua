return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {},
        basedpyright = {},
        ruff = {},
        jsonls = {},
        yamlls = {},
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
