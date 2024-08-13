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


require("lazy").setup({
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  "github/copilot.vim",
})
