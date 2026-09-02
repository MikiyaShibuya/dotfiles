# Power Profile Colors

GNOME Shell extension that colors the "Power Mode" quick settings toggle per power profile.

標準の GNOME Shell 46 では、Performance と Power Saver がどちらも同じアクセント色で「オン」表示になり区別できない。`js/ui/status/powerProfiles.js` の toggle が `checked = activeProfile !== 'balanced'` としているだけで、プロファイル別の style class を持たないため。シェルテーマの CSS 差し替えだけでは判別する手がかりが無く解決できない。

この拡張は `net.hadess.PowerProfiles` の `ActiveProfile` を監視し、toggle に style class を付け替える。色は `stylesheet.css` で与える。

## Colors

| Profile | style class | 通常 | hover | active |
|---------|-------------|------|-------|--------|
| Performance | `ppc-power-performance` | `#1c71d8` | `#3584e4` | `#1a5fb4` |
| Balanced | `ppc-power-balanced` | `#26a269` | `#2ec27e` | `#1c8054` |
| Power Saver | `ppc-power-saver` | `#c01c28` | `#e01b24` | `#a51d2d` |

文字色は白固定。Balanced は標準では非 checked（無色）だが、常時色を付けるため意図的に緑を当てている。結果として3プロファイルすべてが「オン」の見た目になる。

toggle の実体は `QuickMenuToggle`（外側 `.quick-menu-toggle`）で、その内側の `StBoxLayout` に本体ボタン `.quick-toggle` と矢印ボタン `.quick-toggle-arrow` が並ぶ。背景色は両方に当てる必要がある（矢印側はシェルの `BrightnessContrastEffect` で自動的に明るく描画される）。

## Requirements

- GNOME Shell 46
- power-profiles-daemon（`net.hadess.PowerProfiles`）

## Install

```bash
sudo ./install.sh
```

Or via `install_optional.sh` (component: `power_profile_colors`).

Log out and back in after installation. 稼働中の GNOME Shell (Wayland) は拡張ディレクトリを再スキャンしないため、`gnome-extensions enable` は "does not exist" で失敗する（`org.gnome.Shell.Extensions.ReloadExtension` も 46 では deprecated）。`install.sh` はその場合 `enabled-extensions` へ直接登録するので、次回ログインで有効になる。

## Uninstall

```bash
gnome-extensions disable power-profile-colors@custom
rm ~/.local/share/gnome-shell/extensions/power-profile-colors@custom
```

## ログアウトせずに見た目を確認する

`preview-screenshot.py` で、現行セッションに触れず2つ目の gnome-shell をヘッドレス起動して実描画を撮影できる。GNOME拡張やシェルテーマの見た目を検証する汎用手順として使える。

1. 私用の D-Bus セッションバス上でヘッドレスのシェルを起動する。KMS も入力デバイスも掴まないため現行セッションに影響しない。

   ```bash
   dbus-run-session -- sh -c 'echo $DBUS_SESSION_BUS_ADDRESS > /tmp/gs-preview.bus; \
       exec gnome-shell --headless --virtual-monitor 1280x800' > /tmp/gs-preview.log 2>&1 &
   ```

2. 拡張のロード状況を私用バス経由で確認する（`state: 1` = ENABLED、`error` が空なら例外なし）。

   ```bash
   DBUS_SESSION_BUS_ADDRESS="$(cat /tmp/gs-preview.bus)" gdbus call --session --dest org.gnome.Shell \
     --object-path /org/gnome/Shell --method org.gnome.Shell.Extensions.GetExtensionInfo \
     power-profile-colors@custom
   ```

3. クイック設定を開いてプロファイル別に撮影する。

   ```bash
   python3 ./preview-screenshot.py /tmp/gs-preview.bus /tmp
   ```

4. 確認後はヘッドレスシェルを終了する。

   ```bash
   pkill -f "gnome-shell --headless"
   ```

ハマりどころが2つある。

- RemoteDesktop のセッションは**作成した D-Bus 接続に紐づく**。`gdbus call` は呼び出しごとに接続を張り直すため、CreateSession の直後にセッションが消える。1本の接続を保持したまま CreateSession → Start → キー注入まで行う必要がある
- `org.gnome.Shell.Screenshot` は許可された名前の持ち主しか呼べない（`js/ui/screenshot.js` の `DBusSenderChecker`。許可は `org.gnome.SettingsDaemon.MediaKeys` / `org.freedesktop.impl.portal.desktop.gtk` / `org.freedesktop.impl.portal.desktop.gnome` / `org.gnome.Screenshot`）。同じ接続で `org.gnome.Screenshot` を RequestName してから呼ぶと通る

自分で操作して確かめたい場合は入れ子ウィンドウでも起動できる。gnome-session を通さないためシェル単体で、自動起動アプリやセッションサービスは動かない。

```bash
MUTTER_DEBUG_DUMMY_MODE_SPECS=1600x1000 dbus-run-session -- gnome-shell --nested --wayland
```
