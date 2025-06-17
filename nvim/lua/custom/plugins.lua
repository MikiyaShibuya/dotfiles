local plugins = {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "clangd",
        "basedpyright",
        "typescript-language-server",
        "lua-language-server",
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
    config = function()
      -- Disable Copilot's default tab mapping
      vim.g.copilot_no_tab_map = true
      -- Set up Shift-Tab to accept Copilot suggestions
      local keymap = vim.keymap
      keymap.set("i", "<S-Tab>", "copilot#Accept('<CR>')", { expr = true, silent = true, script = true, replace_keycodes = false })
    end,
  },
}

return plugins
