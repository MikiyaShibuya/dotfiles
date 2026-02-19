-- vscode-neovim init.lua
-- Neovim config for use as VSCode backend
-- Keybindings are mapped to VSCode commands via vscode.call()

if not vim.g.vscode then
  return
end

local vscode = require('vscode')
local keymap = vim.keymap.set
local opts = { silent = true, noremap = true }

-- ============================================================
-- Options
-- ============================================================
vim.g.mapleader = ' '
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.showmode = false  -- vscode-neovim側がステータスバーにモード表示するため無効化
vim.opt.timeoutlen = 400
-- NOTE: clipboard と virtualedit は設定しない
-- vscode-neovimはクリップボードをVSCode経由で自動処理する
-- virtualeditはNeovim/VSCode間のカーソル位置ズレの原因になる

-- ============================================================
-- Undo/Redo: VSCode側のundo/redoを使用して同期を保つ
-- ============================================================
vim.keymap.set("n", "u", function() vscode.call('undo') end, opts)
vim.keymap.set("n", "<C-r>", function() vscode.call('redo') end, opts)

-- ============================================================
-- Fast cursor movement (from Neovim init.lua)
-- hjkl を100ms以上押し続けると1回のキー入力で3回分移動
-- ============================================================
vim.g.base_time = 0
vim.g.last_time = 0
vim.g.last_key = ""

local function fast_cursor(key, n_repeat)
  return function()
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

keymap("n", "k", fast_cursor("gk", 3), opts)
keymap("n", "j", fast_cursor("gj", 3), opts)
keymap("n", "h", fast_cursor("h", 3), opts)
keymap("n", "l", fast_cursor("l", 3), opts)

-- ============================================================
-- Highlight yank
-- ============================================================
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- ============================================================
-- formatoptions: don't auto-continue comments
-- ============================================================
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  group = vim.api.nvim_create_augroup("disable_comment", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
    vim.opt_local.formatoptions:append({ "M", "j" })
  end,
})

-- ============================================================
-- General mappings (core/mappings.lua M.general equivalent)
-- ============================================================

-- <Esc> = clear highlights
keymap("n", "<Esc>", "<cmd>noh<CR>", opts)

-- <C-s> = save
keymap("n", "<C-s>", function() vscode.call('workbench.action.files.save') end, opts)

-- Insert mode navigation
keymap("i", "<C-b>", "<ESC>^i", opts)
keymap("i", "<C-e>", "<End>", opts)
keymap("i", "<C-h>", "<Left>", opts)
keymap("i", "<C-l>", "<Right>", opts)
keymap("i", "<C-j>", "<Down>", opts)
keymap("i", "<C-k>", "<Up>", opts)

-- ============================================================
-- Window navigation (C-h/j/k/l)
-- ============================================================
keymap("n", "<C-h>", function() vscode.call('workbench.action.focusLeftGroup') end, opts)
keymap("n", "<C-l>", function() vscode.call('workbench.action.focusRightGroup') end, opts)
keymap("n", "<C-j>", function() vscode.call('workbench.action.focusBelowGroup') end, opts)
keymap("n", "<C-k>", function() vscode.call('workbench.action.focusAboveGroup') end, opts)

-- ============================================================
-- File tree (nvim-tree equivalent)
-- ============================================================
-- <C-n> = toggle sidebar
keymap("n", "<C-n>", function() vscode.call('workbench.action.toggleSidebarVisibility') end, opts)
-- <leader>e = focus explorer
keymap("n", "<leader>e", function() vscode.call('workbench.explorer.fileView.focus') end, opts)

-- ============================================================
-- Buffer/Tab (tabufline equivalent)
-- ============================================================
keymap("n", "<Tab>", function() vscode.call('workbench.action.nextEditor') end, opts)
keymap("n", "<S-Tab>", function() vscode.call('workbench.action.previousEditor') end, opts)
keymap("n", "<leader>x", function() vscode.call('workbench.action.closeActiveEditor') end, opts)
keymap("n", "<leader>b", function() vscode.call('workbench.action.files.newUntitledFile') end, opts)

-- ============================================================
-- Comment (Comment.nvim equivalent)
-- ============================================================
keymap("n", "<leader>/", function() vscode.call('editor.action.commentLine') end, opts)
keymap("v", "<leader>/", function() vscode.call('editor.action.commentLine') end, opts)

-- ============================================================
-- Format
-- ============================================================
keymap("n", "<leader>fm", function() vscode.call('editor.action.formatDocument') end, opts)

-- ============================================================
-- Line numbers
-- ============================================================
keymap("n", "<leader>n", function() vscode.call('editor.action.toggleLineNumbers') end, opts)

-- ============================================================
-- Telescope equivalents (fuzzy finder)
-- ============================================================
keymap("n", "<leader>ff", function() vscode.call('workbench.action.quickOpen') end, opts)
keymap("n", "<leader>fw", function() vscode.call('workbench.action.findInFiles') end, opts)
keymap("n", "<leader>fb", function() vscode.call('workbench.action.showAllEditors') end, opts)
keymap("n", "<leader>fo", function() vscode.call('workbench.action.openRecent') end, opts)
keymap("n", "<leader>fz", function() vscode.call('actions.find') end, opts)
keymap("n", "<leader>fa", function() vscode.call('workbench.action.quickOpen') end, opts)
keymap("n", "<leader>fh", function() vscode.call('workbench.action.openGlobalKeybindings') end, opts)

-- ============================================================
-- Git (gitsigns + Telescope git equivalent)
-- ============================================================
keymap("n", "<leader>cm", function() vscode.call('gitlens.showCommitSearch') end, opts)
keymap("n", "<leader>gt", function() vscode.call('workbench.scm.focus') end, opts)
keymap("n", "<leader>gb", function() vscode.call('gitlens.toggleLineBlame') end, opts)
keymap("n", "<leader>rh", function() vscode.call('git.revertSelectedRanges') end, opts)
keymap("n", "<leader>ph", function() vscode.call('editor.action.dirtydiff.next') end, opts)
keymap("n", "]c", function() vscode.call('workbench.action.editor.nextChange') end, opts)
keymap("n", "[c", function() vscode.call('workbench.action.editor.previousChange') end, opts)

-- ============================================================
-- LSP (lspconfig mappings equivalent)
-- ============================================================
keymap("n", "gd", function() vscode.call('editor.action.revealDefinition') end, opts)
keymap("n", "gD", function() vscode.call('editor.action.revealDeclaration') end, opts)
keymap("n", "gi", function() vscode.call('editor.action.goToImplementation') end, opts)
keymap("n", "gr", function() vscode.call('editor.action.goToReferences') end, opts)
keymap("n", "K", function() vscode.call('editor.action.showHover') end, opts)
keymap("n", "<leader>D", function() vscode.call('editor.action.goToTypeDefinition') end, opts)
keymap("n", "<leader>ra", function() vscode.call('editor.action.rename') end, opts)
keymap("n", "<leader>ca", function() vscode.call('editor.action.quickFix') end, opts)
keymap("v", "<leader>ca", function() vscode.call('editor.action.quickFix') end, opts)
keymap("n", "<leader>ls", function() vscode.call('editor.action.triggerParameterHints') end, opts)
keymap("n", "<leader>lf", function() vscode.call('editor.action.showHover') end, opts)
keymap("n", "[d", function() vscode.call('editor.action.marker.prev') end, opts)
keymap("n", "]d", function() vscode.call('editor.action.marker.next') end, opts)
keymap("n", "<leader>q", function() vscode.call('workbench.action.problems.focus') end, opts)
keymap("n", "<leader>H", function() vscode.call('editor.action.toggleInlayHints') end, opts)

-- ============================================================
-- Terminal
-- ============================================================
keymap("n", "<leader>h", function() vscode.call('workbench.action.terminal.newInActiveWorkspace') end, opts)

-- ============================================================
-- Which-key equivalent
-- ============================================================
keymap("n", "<leader>wK", function() vscode.call('workbench.action.openGlobalKeybindings') end, opts)

-- ============================================================
-- Visual mode: don't overwrite register on paste
-- vscode-neovimではExコマンド連結がモード同期を壊すため、
-- "0p (yank register直接指定) で代替
-- ============================================================
keymap("x", "p", '"0p', opts)
