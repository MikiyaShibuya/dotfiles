require "core"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- require("lazy").setup({
--   "williamboman/mason.nvim",
--   "williamboman/mason-lspconfig.nvim",
--   "neovim/nvim-lspconfig",
--   "github/copilot.vim",
--   -- "altercation/vim-colors-solarized",
--   -- "folke/tokyonight.nvim",
--   -- "glepnir/zephyr-nvim",
--   -- "joshdick/onedark.vim",
--   -- "EdenEast/nightfox.nvim",
-- })

-- vim.cmd.colorscheme("solarized")
-- vim.cmd.colorscheme("tokyonight-moon")
-- vim.cmd.colorscheme("zephyr")
-- vim.cmd.colorscheme("onedark")
-- vim.cmd.colorscheme("carbonfox")



-- This must be set before colorscheme
-- vim.o.termguicolors = false
-- 
-- vim.g.solarized_termcolors = 256
-- vim.g.solarized_visibility = "high"
-- vim.g.solarized_contrast = "high"
-- vim.cmd.colorscheme("solarized")

-- vim.opt.background = "dark"


-- #### Key Config ####
local opt = vim.opt
opt.number = true
opt.virtualedit = "onemore"
opt.encoding = "utf-8"

-- Tab settings
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 0
opt.shiftwidth = 2
opt.expandtab = true

-- Don't swap
opt.swapfile = false

-- Show few lines top and bottom
opt.scrolloff = 5

opt.autoread = true

opt.ignorecase = true

opt.mouse = "a"

opt.syntax = "enable"


local keymap = vim.keymap
local default_opts = { silent = true, noremap = true }

-- Move cursor faster
vim.g.base_time = 0
vim.g.last_time = 0
vim.g.last_key = ""
local function fast_cursor(key, n_repeat)
  return function()
    -- get current time
    local current_time = vim.loop.hrtime() / 1e6

    if current_time > vim.g.last_time + 100 then
      vim.g.base_time = current_time
    end

    if vim.g.last_key ~= key then
      vim.g.base_time = current_time
    end

    vim.g.last_time = current_time
    vim.g.last_key = key

    if vim.g.last_time > vim.g.base_time + 100 then
      vim.cmd('norm! ' .. key:rep(n_repeat))
    else
      vim.cmd('norm! ' .. key)
    end
  end
end
keymap.set("n", "k", fast_cursor("gk", 3), default_opts)
keymap.set("n", "j", fast_cursor("gj", 3), default_opts)
keymap.set("n", "h", fast_cursor("h", 3), default_opts)
keymap.set("n", "l", fast_cursor("l", 3), default_opts)


-- Highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  group = vim.api.nvim_create_augroup("disable_comment", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
    vim.opt_local.formatoptions:append({ "M", "j" })
  end,
})

