local last_time = 0
local on_press_time = 0
local last_key = ""

local acc = function(key)
  local t = vim.loop.now()

  -- Reset on_press_time if no long press or pressed different key
  if t > last_time + 100 then
    on_press_time = t
  end
  if last_key ~= key then
    on_press_time = t
  end

  last_time = t
  last_key = key

  if last_time > on_press_time + 100 then
    vim.cmd('norm! ' .. key .. key .. key)
  else
    vim.cmd('norm! ' .. key)
  end
end

vim.keymap.set('n', 'h', (function() acc("h") end), { noremap = true, desc = 'accelerate when long pressed' })
vim.keymap.set('n', 'j', (function() acc("j") end), { noremap = true, desc = 'accelerate when long pressed' })
vim.keymap.set('n', 'k', (function() acc("k") end), { noremap = true, desc = 'accelerate when long pressed' })
vim.keymap.set('n', 'l', (function() acc("l") end), { noremap = true, desc = 'accelerate when long pressed' })
