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

-- Extrinsics Standalone configuration
local workdir = "/home/mshibuya/pfr/sr_ws/sr01-production/camera-calibration/camera_calib"

-- Common environment for camera calibration
local calib_env = {
  PYTHONPATH = table.concat({
    workdir .. "/baku-baku-camera-calib/production/src/baku_camera_calib",
    workdir .. "/baku-baku-camera-calib/calib",
    workdir,
    workdir .. "/baku-baku-camera-calib/production/install/baku_camera_calib/lib/python3.12/site-packages",
    workdir .. "/baku-baku-camera-calib/production/install/baku_calib_srvs/lib/python3.12/site-packages",
    "/opt/ros/jazzy/lib/python3.12/site-packages",
  }, ":"),
  AMENT_PREFIX_PATH = workdir .. "/baku-baku-camera-calib/production/install/baku_camera_calib:"
    .. workdir .. "/baku-baku-camera-calib/production/install/baku_calib_srvs:/opt/ros/jazzy",
  LD_LIBRARY_PATH = workdir .. "/baku-baku-camera-calib/production/install/baku_calib_srvs/lib"
    .. ":/opt/ros/jazzy/opt/zenoh_cpp_vendor/lib:/opt/ros/jazzy/opt/sdformat_vendor/lib"
    .. ":/opt/ros/jazzy/opt/rviz_ogre_vendor/lib:/opt/ros/jazzy/lib/x86_64-linux-gnu"
    .. ":/opt/ros/jazzy/opt/gz_math_vendor/lib:/opt/ros/jazzy/opt/gz_utils_vendor/lib"
    .. ":/opt/ros/jazzy/opt/gz_tools_vendor/lib:/opt/ros/jazzy/opt/gz_cmake_vendor/lib"
    .. ":/opt/ros/jazzy/lib",
}

-- Custom configuration names (for dedup on reload)
local custom_configs = { "Extrinsics Standalone", "Calib Dialog" }
dap.configurations.python = vim.tbl_filter(function(c)
  return not vim.tbl_contains(custom_configs, c.name)
end, dap.configurations.python or {})

table.insert(dap.configurations.python, {
  type = "python",
  request = "launch",
  name = "Extrinsics Standalone",
  program = workdir .. "/tests/run_extrinsics_standalone.py",
  args = { "calibdata_SR01NONE/front/extrinsics_args_0.npz" },
  cwd = workdir,
  env = calib_env,
  justMyCode = false,
})

table.insert(dap.configurations.python, {
  type = "python",
  request = "launch",
  name = "Calib Dialog",
  program = workdir .. "/camera_calib_dialog.py",
  args = {
    "--hostname", "SR01NONE",
    "--output", "/home/mshibuya/camera_calib_results/SR01NONE_2026-02-19-10-40-46/summary.txt",
    "--camera_type", "front",
    "--robot_type", "SR",
  },
  cwd = workdir,
  env = calib_env,
  justMyCode = false,
})

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
