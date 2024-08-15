local plugins = {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
      }
    }
  },
  "williamboman/mason-lspconfig.nvim",
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
  {
    "github/copilot.vim",
    lazy = false,
  },
}

return plugins
