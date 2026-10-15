// upower の電池履歴と sysstat の CPU 記録を読み、グラフ用のビンに集計する。
// 拡張（GNOME Shell 内）と詳細アプリ（GTK）の両方から import するので Gio/GLib 以外のライブラリに依存しない
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

import {S} from './strings.js';

Gio._promisify(Gio.File.prototype, 'load_contents_async');
Gio._promisify(Gio.Subprocess.prototype, 'communicate_utf8_async');

const UPOWER_DIR = '/var/lib/upower';
const SYSSTAT_DIR = '/var/log/sysstat';
const BATTERY_DIR = '/sys/class/power_supply/BAT0';
const AC_STATES = new Set(['charging', 'fully-charged', 'pending-charge']);
// sysstat が使えないときに、upower の最後の記録を何秒先まで有効とみなすか
const CARRY_LIMIT = 20 * 60;

const decoder = new TextDecoder();

function readSysfs(name) {
    try {
        const [, bytes] = GLib.file_get_contents(`${BATTERY_DIR}/${name}`);
        return decoder.decode(bytes).trim();
    } catch {
        return null;
    }
}

export function currentStatus() {
    const status = readSysfs('status') ?? 'Unknown';
    const powerW = Number(readSysfs('power_now') ?? 0) / 1e6;
    const energy = Number(readSysfs('energy_now') ?? 0);
    const energyFull = Number(readSysfs('energy_full') ?? 0);
    let remainingSec = null;
    if (powerW > 0.5 && status === 'Discharging')
        remainingSec = energy / (powerW * 1e6) * 3600;
    else if (powerW > 0.5 && status === 'Charging')
        remainingSec = (energyFull - energy) / (powerW * 1e6) * 3600;
    return {
        percent: Number(readSysfs('capacity') ?? 0),
        status,
        onAc: readSysfsAc(),
        powerW,
        remainingSec,
    };
}

function readSysfsAc() {
    try {
        const [, bytes] = GLib.file_get_contents('/sys/class/power_supply/AC/online');
        return decoder.decode(bytes).trim() === '1';
    } catch {
        return false;
    }
}

// 同じ型番の電池を入れ替えるとファイルが増えるので、最も新しく更新されたものを使う
function findHistoryFile(kind) {
    const model = readSysfs('model_name');
    const dir = Gio.File.new_for_path(UPOWER_DIR);
    let best = null;
    let bestMtime = -1;
    const iter = dir.enumerate_children('standard::name,time::modified', Gio.FileQueryInfoFlags.NONE, null);
    for (let info = iter.next_file(null); info; info = iter.next_file(null)) {
        const name = info.get_name();
        if (!name.startsWith(`history-${kind}-`) || !name.endsWith('.dat'))
            continue;
        if (model && !name.startsWith(`history-${kind}-${model}`))
            continue;
        const mtime = info.get_attribute_uint64('time::modified');
        if (mtime > bestMtime) {
            best = `${UPOWER_DIR}/${name}`;
            bestMtime = mtime;
        }
    }
    iter.close(null);
    return best;
}

async function readUpower(kind) {
    const path = findHistoryFile(kind);
    if (!path)
        return [];
    const [bytes] = await Gio.File.new_for_path(path).load_contents_async(null);
    const rows = [];
    for (const line of decoder.decode(bytes).split('\n')) {
        const [t, v, state] = line.split('\t');
        if (!state || state === 'unknown')
            continue;
        const value = Number(v);
        // 抜き差しの瞬間に 0 が記録され、グラフが縦に落ちるので捨てる
        if (value <= 0 && (state === 'charging' || state === 'discharging'))
            continue;
        rows.push({t: Number(t), v: value, state});
    }
    return rows.sort((a, b) => a.t - b.t);
}

async function readSadfCpu(path) {
    const proc = Gio.Subprocess.new(['sadf', '-d', '-U', path, '--', '-u'],
        Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
    const [stdout] = await proc.communicate_utf8_async(null, null);
    if (!proc.get_successful())
        return [];
    let idleIdx = -1;
    const rows = [];
    for (const line of stdout.split('\n')) {
        const cols = line.split(';');
        if (line.startsWith('# ')) {
            idleIdx = cols.indexOf('%idle');
            continue;
        }
        // 再起動行は interval が -1 で、CPU 列が無い
        if (idleIdx < 0 || cols.length <= idleIdx || cols[1] === '-1')
            continue;
        rows.push({t: Number(cols[2]), v: 100 - Number(cols[idleIdx])});
    }
    return rows;
}

// sa ファイルは日付（DD）で名前が付き、月をまたぐと上書きされるので、範囲外の行は呼び出し側で落とす
async function readCpu(from, to) {
    const paths = new Set();
    for (let t = from; t < to + 86400; t += 86400) {
        const day = GLib.DateTime.new_from_unix_local(Math.min(t, to)).format('%d');
        paths.add(`${SYSSTAT_DIR}/sa${day}`);
    }
    const chunks = await Promise.all([...paths]
        .filter(p => GLib.file_test(p, GLib.FileTest.EXISTS))
        .map(p => readSadfCpu(p).catch(() => [])));
    return chunks.flat().filter(r => r.t >= from && r.t < to).sort((a, b) => a.t - b.t);
}

export async function load(from, to) {
    const [charge, rate, cpu] = await Promise.all([
        readUpower('charge'), readUpower('rate'), readCpu(from, to)]);
    return {from, to, charge, rate, cpu};
}

function lastBefore(rows, t) {
    let lo = 0;
    let hi = rows.length;
    while (lo < hi) {
        const mid = (lo + hi) >> 1;
        if (rows[mid].t < t)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo > 0 ? rows[lo - 1] : null;
}

function inRange(rows, start, end) {
    return rows.filter(r => r.t >= start && r.t < end);
}

// upower は値が変わったときしか記録しないので、PC が動いていた区間を sysstat の記録で判定する
function isActive(data, start, end) {
    if (inRange(data.charge, start, end).length > 0 || inRange(data.cpu, start, end).length > 0)
        return true;
    if (data.cpu.length > 0)
        return false;
    const last = lastBefore(data.charge, end);
    return last !== null && end - last.t <= CARRY_LIMIT;
}

/** 時刻を binSec ごとに区切り、各区間の電池残量・電力・CPU 使用率を返す */
export function bin(data, binSec, now = Date.now() / 1000) {
    const status = currentStatus();
    const start = Math.floor(data.from / binSec) * binSec;
    const bins = [];
    for (let s = start; s < data.to; s += binSec) {
        const e = s + binSec;
        const isNow = s <= now && now < e;
        const active = isNow || isActive(data, s, e);
        const level = active ? lastBefore(data.charge, Math.min(e, now)) : null;
        const rates = inRange(data.rate, s, e);
        const cpus = inRange(data.cpu, s, e);
        bins.push({
            start: s,
            level: isNow ? status.percent : level?.v ?? null,
            charging: isNow ? status.onAc : AC_STATES.has(level?.state),
            power: rates.length ? mean(rates.map(r => r.v)) : null,
            powerCharging: rates.length ? AC_STATES.has(rates.at(-1).state) : false,
            cpu: cpus.length ? mean(cpus.map(r => r.v)) : null,
        });
    }
    return bins;
}

/** 1日ごとの電池使用量（放電で減った % の合計）・放電中の平均電力・CPU 平均 */
export function daily(data) {
    const days = [];
    for (let s = data.from; s < data.to; s = nextMidnight(s)) {
        const e = Math.min(nextMidnight(s), data.to);
        const charge = inRange(data.charge, s, e);
        let used = 0;
        for (let i = 1; i < charge.length; i++) {
            const [a, b] = [charge[i - 1], charge[i]];
            if (b.state === 'discharging' && b.t - a.t <= CARRY_LIMIT && a.v > b.v)
                used += a.v - b.v;
        }
        const discharge = inRange(data.rate, s, e).filter(r => r.state === 'discharging');
        const cpus = inRange(data.cpu, s, e);
        days.push({
            start: s,
            used: charge.length ? used : null,
            power: discharge.length ? mean(discharge.map(r => r.v)) : null,
            cpu: cpus.length ? mean(cpus.map(r => r.v)) : null,
        });
    }
    return days;
}

export function startOfDay(t) {
    const d = GLib.DateTime.new_from_unix_local(t);
    return GLib.DateTime.new_local(d.get_year(), d.get_month(), d.get_day_of_month(), 0, 0, 0).to_unix();
}

function nextMidnight(t) {
    return GLib.DateTime.new_from_unix_local(startOfDay(t)).add_days(1).to_unix();
}

function mean(values) {
    return values.reduce((a, b) => a + b, 0) / values.length;
}

export function formatDuration(sec) {
    const total = Math.round(sec / 60);
    return S.duration(Math.floor(total / 60), total % 60);
}

export function describe(status) {
    if (status.status === 'Charging')
        return status.remainingSec ? S.untilFull(formatDuration(status.remainingSec)) : S.charging;
    if (status.status === 'Discharging')
        return status.remainingSec ? S.remaining(formatDuration(status.remainingSec)) : S.discharging;
    if (status.onAc)
        return status.status === 'Full' ? S.full : S.onAc;
    return '';
}
