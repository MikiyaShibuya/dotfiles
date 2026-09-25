import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const BATTERY_DIR = '/sys/class/power_supply/BAT0';
const UPDATE_INTERVAL_SEC = 2;

// AC受電中だけプラグアイコンを出す。放電中は数値だけでパネルを詰める
const PLUG_ICON = 'icons/bp-plug-symbolic.svg';

export default class BatteryPowerExtension extends Extension {
    enable() {
        this._timeoutId = 0;
        this._cancellable = new Gio.Cancellable();

        this._icon = new St.Icon({
            styleClass: 'system-status-icon battery-power-icon',
            gicon: Gio.icon_new_for_string(`${this.path}/${PLUG_ICON}`),
            visible: false,
        });
        this._label = new St.Label({
            styleClass: 'battery-power-label',
            yAlign: Clutter.ActorAlign.CENTER,
            text: '--',
        });

        this._box = new St.BoxLayout({
            styleClass: 'battery-power-indicator',
            yAlign: Clutter.ActorAlign.CENTER,
            reactive: false,
        });
        this._box.add_child(this._icon);
        this._box.add_child(this._label);

        // _system は電池アイコンとパーセント表示を持つ SystemIndicator。
        // 末尾に足すことでパネル上の電池表示の直右に並ぶ
        const system = Main.panel.statusArea.quickSettings?._system;
        if (!system) {
            console.warn(`${this.metadata.name}: quickSettings._system が見つからない`);
            return;
        }
        system.add_child(this._box);

        this._update();
        this._timeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, UPDATE_INTERVAL_SEC, () => {
            this._update();
            return GLib.SOURCE_CONTINUE;
        });
    }

    disable() {
        if (this._timeoutId) {
            GLib.source_remove(this._timeoutId);
            this._timeoutId = 0;
        }
        this._cancellable?.cancel();
        this._cancellable = null;

        this._box?.destroy();
        this._box = null;
        this._icon = null;
        this._label = null;
    }

    // sysfs を非同期に読む。ACPI 経由の読み出しは数ms止まることがあり、同期読みだとシェルのフレームを落とす
    _readAsync(name, callback) {
        const file = Gio.File.new_for_path(`${BATTERY_DIR}/${name}`);
        file.load_contents_async(this._cancellable, (obj, res) => {
            try {
                const [, contents] = obj.load_contents_finish(res);
                callback(new TextDecoder().decode(contents).trim());
            } catch (e) {
                if (!e.matches?.(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                    callback(null);
            }
        });
    }

    _update() {
        this._readAsync('status', status => {
            this._readAsync('power_now', power => this._apply(status, power));
        });
    }

    _apply(status, power) {
        if (!this._box)
            return;

        const charging = status === 'Charging';
        // status 取得失敗時にプラグを出すと誤情報になるため、確実にAC受電中と分かる場合だけ表示する
        this._icon.visible = status === 'Charging' || status === 'Full' || status === 'Not charging';

        // 色を変えるのは充電中だけ。満充電やAC接続待機は通常色のまま
        if (charging)
            this._box.add_style_class_name('battery-power-charging');
        else
            this._box.remove_style_class_name('battery-power-charging');

        const microWatts = Number.parseInt(power ?? '', 10);
        this._label.text = Number.isFinite(microWatts)
            ? `${(microWatts / 1000000).toFixed(1)} W`
            : '--';
    }
}
