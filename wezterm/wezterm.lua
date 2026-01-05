local wezterm = require 'wezterm'
local config = {}
local act = wezterm.action

-- タブタイトルのカスタマイズ（SSH接続先を表示）
wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local pane = tab.active_pane
  local title = tab.tab_title
  if #title == 0 then
    title = pane.title
  end

  -- フォアグラウンドプロセス情報を取得
  local info = pane:get_foreground_process_info()
  if info and info.name == 'ssh' and info.argv then
    -- ssh の引数からホスト名を抽出（最後の引数）
    local host = info.argv[#info.argv]
    if host and not host:match('^%-') then
      title = '🖥 ' .. host
    end
  end

  return { { Text = ' ' .. title .. ' ' } }
end)

-- Wayland有効化
config.enable_wayland = true

-- フォント（Nerd Font + 日本語フォールバック）
config.font = wezterm.font_with_fallback {
  'MesloLGS Nerd Font Propo',
  'Noto Sans Mono CJK JP',
}
config.font_size = 10.0

-- アイコングリフの表示を改善
config.allow_square_glyphs_to_overflow_width = 'WhenFollowedBySpace'

config.colors = {
  foreground = '#FFFFFF',
}

-- GNOME Terminal互換キーバインド
config.keys = {
  -- コピー・ペースト
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- タブ操作
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = true } },
  { key = 'n', mods = 'CTRL|SHIFT', action = act.SpawnWindow },
  { key = 'q', mods = 'CTRL|SHIFT', action = act.QuitApplication },

  -- タブ切り替え
  { key = 'PageUp', mods = 'CTRL', action = act.ActivateTabRelative(-1) },
  { key = 'PageDown', mods = 'CTRL', action = act.ActivateTabRelative(1) },

  -- タブ移動
  { key = 'PageUp', mods = 'CTRL|SHIFT', action = act.MoveTabRelative(-1) },
  { key = 'PageDown', mods = 'CTRL|SHIFT', action = act.MoveTabRelative(1) },

  -- Alt+数字でタブ切り替え
  { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
  { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
  { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
  { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
  { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
  { key = '6', mods = 'ALT', action = act.ActivateTab(5) },
  { key = '7', mods = 'ALT', action = act.ActivateTab(6) },
  { key = '8', mods = 'ALT', action = act.ActivateTab(7) },
  { key = '9', mods = 'ALT', action = act.ActivateTab(-1) },

  -- ズーム
  { key = '+', mods = 'CTRL|SHIFT', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },
}

return config
