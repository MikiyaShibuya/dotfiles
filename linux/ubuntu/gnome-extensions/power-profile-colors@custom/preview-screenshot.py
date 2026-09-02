#!/usr/bin/env python3
"""ヘッドレスgnome-shellのクイック設定を開き、電源プロファイル別にスクショを撮る。

現行セッションに触れず、2つ目のgnome-shellをヘッドレス起動して実描画を確認する。

事前にヘッドレスシェルを起動しておく（バスアドレスをファイルに落とす）:

    dbus-run-session -- sh -c 'echo $DBUS_SESSION_BUS_ADDRESS > /tmp/gs-preview.bus; \
        exec gnome-shell --headless --virtual-monitor 1280x800' > /tmp/gs-preview.log 2>&1 &

使い方:

    python3 preview-screenshot.py [バスアドレスファイル] [出力ディレクトリ]

注意点2つ:
- RemoteDesktopのセッションは作成したD-Bus接続に紐づく。`gdbus call` のように
  呼び出しごとに接続を張り直すとセッションが即消えるため、1本の接続を保持する
- org.gnome.Shell.Screenshot は許可された名前の持ち主しか呼べない
  (js/ui/screenshot.js の DBusSenderChecker)。同じ接続で org.gnome.Screenshot を
  RequestName してから呼ぶ
"""
import os
import sys
import time

import gi
gi.require_version('Gio', '2.0')
from gi.repository import Gio, GLib

BUS_ADDR_FILE = sys.argv[1] if len(sys.argv) > 1 else '/tmp/gs-preview.bus'
OUT_DIR = sys.argv[2] if len(sys.argv) > 2 else '/tmp'

RD_NAME = 'org.gnome.Mutter.RemoteDesktop'
RD_PATH = '/org/gnome/Mutter/RemoteDesktop'
KEYSYM_SUPER_L = 0xffeb
KEYSYM_S = 0x0073

PROFILES = ['balanced', 'performance', 'power-saver']
# 撮影後に戻すプロファイル。プロファイルは実機共通のため必ず復帰させる
RESTORE_PROFILE = 'balanced'


def call(conn, dest, path, iface, method, params, reply_type=None):
    return conn.call_sync(dest, path, iface, method, params, reply_type,
                          Gio.DBusCallFlags.NONE, 10000, None)


def main():
    if not os.path.exists(BUS_ADDR_FILE):
        sys.exit(f'バスアドレスファイルが無い: {BUS_ADDR_FILE} '
                 '(ヘッドレスシェルを起動したか確認する)')

    with open(BUS_ADDR_FILE) as f:
        bus_addr = f.read().strip()

    session = Gio.DBusConnection.new_for_address_sync(
        bus_addr,
        Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT |
        Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
        None, None)
    system = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)

    # Screenshot API の許可リストにある名前をこの接続で取得する
    call(session, 'org.freedesktop.DBus', '/org/freedesktop/DBus',
         'org.freedesktop.DBus', 'RequestName',
         GLib.Variant('(su)', ('org.gnome.Screenshot', 0)),
         GLib.VariantType('(u)'))
    time.sleep(1.0)

    res = call(session, RD_NAME, RD_PATH, RD_NAME, 'CreateSession', None,
               GLib.VariantType('(o)'))
    sess_path = res.unpack()[0]
    call(session, RD_NAME, sess_path, f'{RD_NAME}.Session', 'Start', None, None)

    def keysym(sym, pressed):
        call(session, RD_NAME, sess_path, f'{RD_NAME}.Session',
             'NotifyKeyboardKeysym', GLib.Variant('(ub)', (sym, pressed)), None)

    def set_profile(profile):
        call(system, 'net.hadess.PowerProfiles', '/net/hadess/PowerProfiles',
             'org.freedesktop.DBus.Properties', 'Set',
             GLib.Variant('(ssv)', ('net.hadess.PowerProfiles', 'ActiveProfile',
                                    GLib.Variant('s', profile))), None)

    def screenshot(path):
        res = call(session, 'org.gnome.Shell.Screenshot',
                   '/org/gnome/Shell/Screenshot', 'org.gnome.Shell.Screenshot',
                   'Screenshot', GLib.Variant('(bbs)', (False, False, path)),
                   GLib.VariantType('(bs)'))
        return res.unpack()

    # Super+s でクイック設定を開く
    keysym(KEYSYM_SUPER_L, True)
    keysym(KEYSYM_S, True)
    keysym(KEYSYM_S, False)
    keysym(KEYSYM_SUPER_L, False)
    time.sleep(1.5)

    try:
        for profile in PROFILES:
            set_profile(profile)
            time.sleep(1.0)
            ok, used = screenshot(os.path.join(OUT_DIR, f'power-profile-{profile}.png'))
            print(f'{profile}: ok={ok} path={used}')
    finally:
        set_profile(RESTORE_PROFILE)
        print(f'restored: {RESTORE_PROFILE}')


if __name__ == '__main__':
    main()
