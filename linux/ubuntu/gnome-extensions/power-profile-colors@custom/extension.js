import Gio from 'gi://Gio';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const BUS_NAME = 'net.hadess.PowerProfiles';
const OBJECT_PATH = '/net/hadess/PowerProfiles';
const IFACE_NAME = 'net.hadess.PowerProfiles';

// stylesheet.css 側のクラス名と対応
const PROFILE_STYLE_CLASSES = {
    'performance': 'ppc-power-performance',
    'balanced': 'ppc-power-balanced',
    'power-saver': 'ppc-power-saver',
};

export default class PowerProfileColorsExtension extends Extension {
    enable() {
        this._proxy = null;
        this._propsChangedId = 0;
        this._nameOwnerId = 0;
        this._styledToggle = null;
        this._appliedClass = null;
        this._cancellable = new Gio.Cancellable();

        // シェル内部のトグルが持つproxyには触らず、自前のproxyでActiveProfileを見る
        Gio.DBusProxy.new_for_bus(
            Gio.BusType.SYSTEM,
            Gio.DBusProxyFlags.DO_NOT_AUTO_START,
            null,
            BUS_NAME, OBJECT_PATH, IFACE_NAME,
            this._cancellable,
            (obj, res) => {
                let proxy;
                try {
                    proxy = Gio.DBusProxy.new_for_bus_finish(res);
                } catch (e) {
                    if (!e.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                        console.warn(`${this.metadata.name}: PowerProfilesのproxy生成に失敗: ${e.message}`);
                    return;
                }

                // disable()と競合した場合は何もしない
                if (!this._cancellable) {
                    return;
                }

                this._proxy = proxy;
                this._propsChangedId =
                    proxy.connect('g-properties-changed', () => this._sync());
                this._nameOwnerId =
                    proxy.connect('notify::g-name-owner', () => this._sync());
                this._sync();
            });
    }

    disable() {
        this._cancellable?.cancel();
        this._cancellable = null;

        if (this._proxy) {
            if (this._propsChangedId)
                this._proxy.disconnect(this._propsChangedId);
            if (this._nameOwnerId)
                this._proxy.disconnect(this._nameOwnerId);
            this._proxy = null;
        }
        this._propsChangedId = 0;
        this._nameOwnerId = 0;

        this._removeStyle();
        this._styledToggle = null;
    }

    /**
     * Power Modeトグル（QuickMenuToggle）を取得する。
     * 内部クラス名には依存せず、style classで同定する。
     *
     * @returns {Clutter.Actor|null} トグル本体、見つからなければnull
     */
    _findToggle() {
        const items =
            Main.panel?.statusArea?.quickSettings?._powerProfiles?.quickSettingsItems;
        if (!Array.isArray(items))
            return null;

        return items.find(
            item => item.has_style_class_name?.('quick-menu-toggle')) ?? null;
    }

    _activeProfile() {
        if (!this._proxy?.g_name_owner)
            return null;

        const variant = this._proxy.get_cached_property('ActiveProfile');
        return variant?.deepUnpack() ?? null;
    }

    _removeStyle() {
        if (this._styledToggle && this._appliedClass)
            this._styledToggle.remove_style_class_name(this._appliedClass);
        this._appliedClass = null;
    }

    _sync() {
        const toggle = this._findToggle();
        const profile = this._activeProfile();
        const styleClass = profile ? PROFILE_STYLE_CLASSES[profile] ?? null : null;

        if (this._styledToggle === toggle && this._appliedClass === styleClass)
            return;

        this._removeStyle();
        this._styledToggle = toggle;

        if (toggle && styleClass) {
            toggle.add_style_class_name(styleClass);
            this._appliedClass = styleClass;
        }
    }
}
