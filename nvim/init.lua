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
vim.keymap.set("n", "k", fast_cursor("k", 3), default_opts)
vim.keymap.set("n", "j", fast_cursor("j", 3), default_opts)
vim.keymap.set("n", "h", fast_cursor("h", 3), default_opts)
vim.keymap.set("n", "l", fast_cursor("l", 3), default_opts)


require("lazy").setup({
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  "github/copilot.vim",
})
