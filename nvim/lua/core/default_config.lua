local M = {}

M.options = {
  nvchad_branch = "v3.0",
}

M.base46 = {
  theme = "onedark",
  theme_toggle = { "onedark", "one_light" },
  hl_add = {},
  hl_override = {},
  transparency = false,
  integrations = {},
}

M.ui = {
  cmp = {
    icons = true,
    lspkind_text = true,
    style = "default",
  },

  telescope = { style = "borderless" },

  statusline = {
    theme = "default",
    separator_style = "default",
  },

  tabufline = {
    show_numbers = false,
    enabled = true,
    lazyload = true,
  },

  nvdash = {
    load_on_startup = false,

    header = {
      "           ▄ ▄                   ",
      "       ▄   ▄▄▄     ▄ ▄▄▄ ▄ ▄     ",
      "       █ ▄ █▄█ ▄▄▄ █ █▄█ █ █     ",
      "    ▄▄ █▄█▄▄▄█ █▄█▄█▄▄█▄▄█ █     ",
      "  ▄ █▄▄█ ▄ ▄▄ ▄█ ▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ",
      "  █▄▄▄▄ ▄▄▄ █ ▄ ▄▄▄ ▄ ▄▄▄ ▄ ▄ █ ▄",
      "▄ █ █▄█ █▄█ █ █ █▄█ █ █▄█ ▄▄▄ █ █",
      "█▄█ ▄ █▄▄█▄▄█ █ ▄▄█ █ ▄ █ █▄█▄█ █",
      "    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█ █▄█▄▄▄█    ",
    },

    buttons = {
      { txt = "  Find File", keys = "Spc f f", cmd = "Telescope find_files" },
      { txt = "󰈚  Recent Files", keys = "Spc f o", cmd = "Telescope oldfiles" },
      { txt = "󰈭  Find Word", keys = "Spc f w", cmd = "Telescope live_grep" },
      { txt = "  Bookmarks", keys = "Spc m a", cmd = "Telescope marks" },
      { txt = "  Themes", keys = "Spc t h", cmd = "Telescope themes" },
      { txt = "  Mappings", keys = "Spc c h", cmd = "NvCheatsheet" },
    },
  },

  cheatsheet = { theme = "grid" },

  lsp = {
    signature = true,
  },
}

M.plugins = ""

M.lazy_nvim = require "plugins.configs.lazy_nvim"

M.mappings = require "core.mappings"

return M
