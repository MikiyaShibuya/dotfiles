local dap = require("dap")
local dapui = require("dapui")
local dap_python = require("dap-python")

-- Setup debugpy with system python
dap_python.setup("/usr/bin/python3")

-- Breakpoint signs (VS Code style)
vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapLogPoint",            { text = "◈", texthl = "DapLogPoint" })
vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine" })

-- Highlight groups
vim.api.nvim_set_hl(0, "DapBreakpoint",  { fg = "#e51400" })  -- red
vim.api.nvim_set_hl(0, "DapLogPoint",    { fg = "#e5e500" })  -- yellow
vim.api.nvim_set_hl(0, "DapStopped",     { fg = "#98c379" })  -- green
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e4d2e" })  -- dark green background

-- Setup DAP UI
dapui.setup()

-- Auto open/close DAP UI
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- 社内プロジェクトの launch 設定は非公開レポに置く。README "Private Configuration" 参照。
-- pcall を使わないのは、モジュール内のエラーを握り潰さないため
local dap_projects = vim.fn.stdpath("config") .. "/lua/custom/configs/dap_projects.lua"
if vim.fn.filereadable(dap_projects) == 1 then
  require("custom.configs.dap_projects").setup(dap)
end

-- Keymaps
local keymap = vim.keymap
keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP Continue / Start" })
keymap.set("n", "<leader>dn", dap.step_over, { desc = "DAP Step Over" })
keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP Step Into" })
keymap.set("n", "<leader>do", dap.step_out, { desc = "DAP Step Out" })
keymap.set("n", "<leader>dr", dap.restart, { desc = "DAP Restart" })
keymap.set("n", "<leader>dx", dap.terminate, { desc = "DAP Terminate" })
keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI Toggle" })
keymap.set("n", "<leader>de", dapui.eval, { desc = "DAP Eval" })
keymap.set("v", "<leader>de", dapui.eval, { desc = "DAP Eval Selection" })
