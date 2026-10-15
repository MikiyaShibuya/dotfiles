// 電池履歴の詳細ウィンドウ。拡張のカードから `gjs -m app.js` で起動する
import Adw from 'gi://Adw?version=1';
import Gdk from 'gi://Gdk?version=4.0';
import GLib from 'gi://GLib';
import Gtk from 'gi://Gtk?version=4.0';
import System from 'system';

import * as Chart from './chart.js';
import * as History from './history.js';
import {S} from './strings.js';

const DAYS = 7;
const BIN_SEC = 15 * 60;
const RELOAD_SEC = 60;

const CSS = `
.hero { padding: 18px 20px; }
.hero-percent { font-size: 44px; font-weight: 800; font-feature-settings: "tnum"; }
.hero-power { font-feature-settings: "tnum"; }
levelbar.hero-level > trough { min-height: 10px; border-radius: 999px; }
levelbar.hero-level > trough > block { border-radius: 999px; }
levelbar.hero-level > trough > block.filled { background-color: @accent_bg_color; }
levelbar.hero-level.charging > trough > block.filled { background-color: @success_color; }
.chart-card { padding: 14px 16px 10px 16px; }
.readout { font-feature-settings: "tnum"; }
`;

class ChartCard {
    constructor(title, height) {
        this.widget = new Gtk.Box({orientation: Gtk.Orientation.VERTICAL, spacing: 2, cssClasses: ['card', 'chart-card']});

        const header = new Gtk.Box({spacing: 8});
        this._title = new Gtk.Label({label: title, xalign: 0, cssClasses: ['heading']});
        header.append(this._title);
        this._readout = new Gtk.Label({hexpand: true, xalign: 1, cssClasses: ['dim-label', 'numeric', 'readout']});
        header.append(this._readout);
        this.widget.append(header);

        this._summary = new Gtk.Label({xalign: 0, cssClasses: ['caption', 'dim-label']});
        this.widget.append(this._summary);

        this._area = new Gtk.DrawingArea({contentHeight: height, marginTop: 8});
        this._area.set_draw_func((area, cr, width, h) => this._draw(area, cr, width, h));
        this.widget.append(this._area);

        this._selected = null;
        this._hitTest = () => null;
        const motion = new Gtk.EventControllerMotion();
        motion.connect('motion', (_c, x) => this._select(this._hitTest(x)));
        motion.connect('leave', () => this._select(null));
        this._area.add_controller(motion);
    }

    /** spec: {title, kind: 'bars'|'area', values, opts, summary, readout(i)} */
    set(spec) {
        this._spec = spec;
        this._title.label = spec.title;
        this._summary.label = spec.summary;
        this._select(null);
    }

    _select(index) {
        this._selected = index;
        const text = index === null ? null : this._spec?.readout(index);
        this._readout.label = text ?? '';
        this._area.queue_draw();
    }

    _draw(area, cr, width, height) {
        if (!this._spec)
            return;
        const fg = area.get_color();
        this._hitTest = Chart[this._spec.kind](cr, width, height, this._spec.values, {
            ...this._spec.opts,
            fg: [fg.red, fg.green, fg.blue],
            font: area.get_pango_context().get_font_description(),
            fontPx: 11,
            // 縦に並ぶグラフの時刻位置を揃えるため、目盛り文字の無いグラフにも同じ余白を取る
            axisWidth: Chart.AXIS_WIDTH,
            selected: this._selected,
        });
        cr.$dispose();
    }
}

class Hero {
    constructor() {
        this.widget = new Gtk.Box({orientation: Gtk.Orientation.VERTICAL, spacing: 12, cssClasses: ['card', 'hero']});
        const row = new Gtk.Box({spacing: 16});
        this._percent = new Gtk.Label({cssClasses: ['hero-percent'], valign: Gtk.Align.CENTER});
        row.append(this._percent);

        const text = new Gtk.Box({orientation: Gtk.Orientation.VERTICAL, valign: Gtk.Align.CENTER, hexpand: true});
        this._state = new Gtk.Label({xalign: 0, cssClasses: ['title-4']});
        this._detail = new Gtk.Label({xalign: 0, cssClasses: ['dim-label']});
        text.append(this._state);
        text.append(this._detail);
        row.append(text);

        this._power = new Gtk.Label({cssClasses: ['title-3', 'hero-power'], valign: Gtk.Align.CENTER});
        row.append(this._power);
        this.widget.append(row);

        this._level = new Gtk.LevelBar({minValue: 0, maxValue: 100, cssClasses: ['hero-level']});
        // 既定の low/high/full の色分けは使わず、充電中かどうかだけで色を変える
        for (const name of [Gtk.LEVEL_BAR_OFFSET_LOW, Gtk.LEVEL_BAR_OFFSET_HIGH, Gtk.LEVEL_BAR_OFFSET_FULL])
            this._level.remove_offset_value(name);
        this.widget.append(this._level);
    }

    update() {
        const s = History.currentStatus();
        this._percent.label = `${s.percent}%`;
        this._state.label = {
            Charging: S.charging, Discharging: S.onBattery, Full: S.full, 'Not charging': S.onAc,
        }[s.status] ?? s.status;
        this._detail.label = s.status === 'Discharging' || s.status === 'Charging'
            ? History.describe(s) : (s.onAc ? S.acAdapter : '');
        this._power.label = s.powerW > 0.5 ? `${s.powerW.toFixed(1)} W` : '';
        this._level.value = s.percent;
        if (s.onAc)
            this._level.add_css_class('charging');
        else
            this._level.remove_css_class('charging');
    }
}

function clock(t) {
    return GLib.DateTime.new_from_unix_local(t).format('%H:%M');
}

function dayLabel(t, today) {
    if (t === today)
        return S.today;
    const d = GLib.DateTime.new_from_unix_local(t);
    return S.dayLabel(d.get_day_of_month(), d.get_day_of_week() % 7);
}

function niceMax(values, step, min) {
    const max = Math.max(min, ...values.filter(v => v !== null));
    return Math.ceil(max / step) * step;
}

function average(values) {
    const xs = values.filter(v => v !== null);
    return xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null;
}

function fmt(v, digits, unit) {
    return v === null ? '—' : `${v.toFixed(digits)}${unit}`;
}

function daySpecs(data, now) {
    const bins = History.bin({...data, from: now - 24 * 3600, to: now}, BIN_SEC, now);
    const xLabels = [];
    bins.forEach((b, i) => {
        const d = GLib.DateTime.new_from_unix_local(b.start);
        if (d.get_minute() === 0 && d.get_hour() % 6 === 0)
            xLabels.push({index: i, label: S.hourLabel(d.get_hour())});
    });
    const range = i => `${clock(bins[i].start)}–${clock(bins[i].start + BIN_SEC)}`;
    const powerMax = niceMax(bins.map(b => b.power), 10, 10);
    const discharge = bins.filter(b => b.power !== null && !b.powerCharging).map(b => b.power);

    return [{
        title: S.level,
        kind: 'bars',
        values: bins.map(b => ({value: b.level, accent: b.charging})),
        opts: {yMax: 100, yTicks: [0, 50, 100], xLabels},
        summary: S.levelSummary,
        readout: i => bins[i].level === null ? `${range(i)} · ${S.noRecord}`
            : `${range(i)} · ${bins[i].level.toFixed(0)}%${bins[i].charging ? ` · ${S.charging}` : ''}`,
    }, {
        title: S.power,
        kind: 'bars',
        values: bins.map(b => ({value: b.power, accent: b.powerCharging})),
        opts: {yMax: powerMax, yTicks: [0, powerMax / 2, powerMax], yFormat: v => `${v}W`, xLabels},
        summary: S.powerSummary(fmt(average(discharge), 1, ' W')),
        readout: i => bins[i].power === null ? `${range(i)} · ${S.noRecord}`
            : `${range(i)} · ${bins[i].power.toFixed(1)} W ${bins[i].powerCharging ? S.powerIn : S.powerOut}`,
    }, {
        title: S.cpu,
        kind: 'area',
        values: bins.map(b => b.cpu),
        opts: {yMax: 100, yTicks: [0, 50, 100], xLabels},
        summary: S.cpuDaySummary(fmt(average(bins.map(b => b.cpu)), 0, '%')),
        readout: i => `${range(i)} · ${fmt(bins[i].cpu, 0, '%')}`,
    }];
}

function weekSpecs(data, now) {
    const days = History.daily(data);
    const today = History.startOfDay(now);
    const xLabels = days.map((d, i) => ({index: i, label: dayLabel(d.start, today)}));
    const usedMax = niceMax(days.map(d => d.used), 50, 100);
    const powerMax = niceMax(days.map(d => d.power), 10, 10);
    const date = i => dayLabel(days[i].start, today);

    return [{
        title: S.usage,
        kind: 'bars',
        values: days.map(d => ({value: d.used, accent: false})),
        opts: {yMax: usedMax, yTicks: [0, usedMax / 2, usedMax], yFormat: v => `${v}%`, xLabels},
        summary: S.usageSummary,
        readout: i => `${date(i)} · ${fmt(days[i].used, 0, '%')}`,
    }, {
        title: S.avgPower,
        kind: 'bars',
        values: days.map(d => ({value: d.power, accent: false})),
        opts: {yMax: powerMax, yTicks: [0, powerMax / 2, powerMax], yFormat: v => `${v}W`, xLabels},
        summary: S.avgPowerSummary,
        readout: i => `${date(i)} · ${fmt(days[i].power, 1, ' W')}`,
    }, {
        title: S.cpu,
        kind: 'bars',
        values: days.map(d => ({value: d.cpu, accent: false})),
        opts: {yMax: 100, yTicks: [0, 50, 100], xLabels},
        summary: S.cpuWeekSummary,
        readout: i => `${date(i)} · ${fmt(days[i].cpu, 0, '%')}`,
    }];
}

function buildWindow(app) {
    const provider = new Gtk.CssProvider();
    provider.load_from_string(CSS);
    Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    const window = new Adw.ApplicationWindow({application: app, title: S.battery, defaultWidth: 540, defaultHeight: 900});

    const dayButton = new Gtk.ToggleButton({label: S.past24h, active: true});
    const weekButton = new Gtk.ToggleButton({label: S.past7d, group: dayButton});
    const switcher = new Gtk.Box({cssClasses: ['linked']});
    switcher.append(dayButton);
    switcher.append(weekButton);

    const header = new Adw.HeaderBar({titleWidget: switcher});
    const toolbar = new Adw.ToolbarView();
    toolbar.add_top_bar(header);

    const hero = new Hero();
    const cards = [new ChartCard('', 150), new ChartCard('', 120), new ChartCard('', 110)];
    const column = new Gtk.Box({
        orientation: Gtk.Orientation.VERTICAL, spacing: 14,
        marginTop: 12, marginBottom: 24, marginStart: 16, marginEnd: 16,
    });
    column.append(hero.widget);
    cards.forEach(c => column.append(c.widget));
    column.append(new Gtk.Label({
        label: S.footer,
        cssClasses: ['caption', 'dim-label'], marginTop: 6,
    }));

    const clamp = new Adw.Clamp({maximumSize: 640, child: column});
    toolbar.content = new Gtk.ScrolledWindow({child: clamp, hscrollbarPolicy: Gtk.PolicyType.NEVER});
    window.content = toolbar;

    let data = null;
    const render = () => {
        if (!data)
            return;
        const now = Date.now() / 1000;
        const specs = weekButton.active ? weekSpecs(data, now) : daySpecs(data, now);
        specs.forEach((spec, i) => cards[i].set(spec));
    };
    const reload = async () => {
        hero.update();
        const now = Date.now() / 1000;
        data = await History.load(History.startOfDay(now) - (DAYS - 1) * 86400, now);
        render();
    };
    dayButton.connect('toggled', render);

    reload().catch(logError);
    const timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, RELOAD_SEC, () => {
        reload().catch(logError);
        return GLib.SOURCE_CONTINUE;
    });
    window.connect('close-request', () => {
        GLib.source_remove(timer);
        return false;
    });
    return window;
}

const app = new Adw.Application({applicationId: 'local.custom.PowerHistory'});
app.connect('activate', () => (app.activeWindow ?? buildWindow(app)).present());
await app.runAsync([System.programInvocationName, ...ARGV]);
