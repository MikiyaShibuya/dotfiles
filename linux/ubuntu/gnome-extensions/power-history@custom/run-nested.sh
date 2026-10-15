#!/bin/sh
# 本番セッションに入れずに試すため、入れ子の GNOME Shell をウィンドウとして起動し、その中で拡張を有効にする。
# 設定はメモリ上に置くので、本体の有効化済み拡張などは変わらない
set -eu
here=$(cd "$(dirname "$0")" && pwd)
uuid=power-history@custom
data=$(mktemp -d)
trap 'rm -rf "$data"' EXIT
mkdir -p "$data/gnome-shell/extensions"
ln -s "$here" "$data/gnome-shell/extensions/$uuid"

export XDG_DATA_HOME="$data" GSETTINGS_BACKEND=memory UUID="$uuid"
export MUTTER_DEBUG_DUMMY_MODE_SPECS="${MUTTER_DEBUG_DUMMY_MODE_SPECS:-1280x960}"
dbus-run-session -- sh -c '
  gnome-shell --nested --wayland --no-x11 &
  shell=$!
  until gdbus introspect --session --dest org.gnome.Shell --object-path /org/gnome/Shell >/dev/null 2>&1; do
    sleep 0.5
  done
  # 起動直後は有効化の要求が取りこぼされることがあるので、反映されるまで繰り返す
  until gnome-extensions info "$UUID" | grep -q "Enabled: Yes"; do
    gnome-extensions enable "$UUID" || true
    sleep 0.5
  done
  wait "$shell"
'
