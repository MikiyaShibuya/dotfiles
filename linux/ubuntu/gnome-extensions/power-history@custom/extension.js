import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {QuickSettingsItem} from 'resource:///org/gnome/shell/ui/quickSettings.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

import * as Chart from './chart.js';
import * as History from './history.js';
import {S} from './strings.js';

const HOURS = 24;
const BIN_SEC = 30 * 60;
const SETUP_RETRY_MS = 200;
// クイック設定から隠すトグル（夜間モード・スタイル切替・キーボードライト・機内モード）を持つ QuickSettings のプロパティ名
const HIDDEN_INDICATORS = ['_nightLight', '_darkMode', '_backlight', '_rfkill'];

// 各トグルは機能の有無に応じて自分で visible を切り替えるので、visible には触らずメニューから外して隠す。
// 無効化時は元の位置と列幅で戻す
class RemovedItem {
    constructor(grid, item) {
        this._grid = grid;
        this._item = item;
        this._next = item.get_next_sibling();
        this._columnSpan = grid.layout_manager.get_child_meta(grid, item).columnSpan;
        grid.remove_child(item);
    }

    // 外した順の逆で戻せば、覚えておいた次の兄弟は戻す時点でメニューにある
    restore() {
        // 親に追加すると show-on-set-parent で表示されてしまうので、トグル自身が決めた visible に戻す
        const visible = this._item.visible;
        if (this._next?.get_parent() === this._grid)
            this._grid.insert_child_below(this._item, this._next);
        else
            this._grid.add_child(this._item);
        this._item.visible = visible;
        this._grid.layout_manager.child_set_property(this._grid, this._item, 'column-span', this._columnSpan);
    }
}

const BatteryCard = GObject.registerClass(
class BatteryCard extends QuickSettingsItem {
    _init(onActivate) {
        super._init({
            styleClass: 'power-history-card',
            canFocus: true,
            xExpand: true,
            accessibleName: S.cardAccessible,
        });
        this._bins = [];
        this._cancelled = false;

        const box = new St.BoxLayout({vertical: true, xExpand: true});
        this.child = box;

        // 見出しと残り時間を別ラベルにすると和文と欧文でフォントの高さが違い、ベースラインがずれるので1つにまとめる
        this._heading = new St.Label({styleClass: 'power-history-heading', xExpand: true});
        box.add_child(this._heading);

        this._chart = new St.DrawingArea({styleClass: 'power-history-chart', xExpand: true});
        this._chart.connect('repaint', area => this._repaint(area));
        box.add_child(this._chart);

        this.connect('clicked', onActivate);
        this.connect('destroy', () => (this._cancelled = true));
    }

    async refresh() {
        const status = History.currentStatus();
        const detail = History.describe(status);
        const suffix = detail ? `<span fgalpha="60%"> · ${GLib.markup_escape_text(detail, -1)}</span>` : '';
        this._heading.clutterText.set_markup(
            `<b>${GLib.markup_escape_text(S.battery, -1)}</b>${suffix}`);

        const now = Date.now() / 1000;
        const data = await History.load(now - HOURS * 3600, now);
        if (this._cancelled)
            return;
        this._bins = History.bin(data, BIN_SEC, now);
        this._chart.queue_repaint();
    }

    _repaint(area) {
        const cr = area.get_context();
        const [width, height] = area.get_surface_size();
        const node = area.get_theme_node();
        const fg = node.get_foreground_color();
        Chart.bars(cr, width, height,
            this._bins.map(b => ({value: b.level, accent: b.charging})), {
                yMax: 100,
                yTicks: [0, 50, 100],
                xLabels: hourLabels(this._bins),
                fg: [fg.red / 255, fg.green / 255, fg.blue / 255],
                font: node.get_font(),
                fontPx: 10,
            });
        cr.$dispose();
    }
});

function hourLabels(bins) {
    const labels = [];
    bins.forEach((b, i) => {
        const d = GLib.DateTime.new_from_unix_local(b.start);
        if (d.get_minute() === 0 && d.get_hour() % 6 === 0)
            labels.push({index: i, label: S.hourLabel(d.get_hour())});
    });
    return labels;
}

export default class PowerHistoryExtension extends Extension {
    enable() {
        this._retryId = 0;
        this._removedItems = [];
        this._card = new BatteryCard(() => this._openDetails());
        this._insertCard();
    }

    disable() {
        if (this._retryId)
            GLib.source_remove(this._retryId);
        this._retryId = 0;
        // カードの直前にあったトグルを正しい位置に戻すため、カードを消す前に戻す
        this._removedItems.reverse().forEach(r => r.restore());
        this._removedItems = [];
        this._card?.destroy();
        this._card = null;
    }

    // quickSettings は _system 等を非同期に組み立てるので、シェル起動直後はまだ無いことがある
    _insertCard() {
        const quickSettings = Main.panel.statusArea.quickSettings;
        const systemItem = quickSettings._system?.quickSettingsItems.at(-1);
        if (!systemItem) {
            this._retryId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, SETUP_RETRY_MS, () => {
                this._retryId = 0;
                this._insertCard();
                return GLib.SOURCE_REMOVE;
            });
            return;
        }
        // mac の電池メニューに倣い、電池％のある最上段の直下に置く
        quickSettings.menu.insertItemBefore(this._card, systemItem.get_next_sibling(), 2);
        // _system と同じ箇所で同期的に作られるので、ここまで来れば揃っている
        this._removedItems = HIDDEN_INDICATORS
            .flatMap(name => quickSettings[name]?.quickSettingsItems ?? [])
            .map(item => new RemovedItem(quickSettings.menu._grid, item));
        quickSettings.menu.connectObject('open-state-changed', (_menu, isOpen) => {
            if (isOpen)
                this._card.refresh().catch(e => console.error(`${this.metadata.name}: ${e}`));
        }, this._card);
    }

    _openDetails() {
        Main.panel.closeQuickSettings();
        // Adw.Application が単一インスタンスなので、既に開いていればそのウィンドウが前に出る
        const proc = Gio.Subprocess.new(['gjs', '-m', `${this.path}/app.js`], Gio.SubprocessFlags.NONE);
        proc.wait_async(null, null);
    }
}
