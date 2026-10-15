// Cairo で棒グラフと面グラフを描く。St.DrawingArea と Gtk.DrawingArea の両方で同じ見た目にするため、
// ツールキットに依存する色やフォントは呼び出し側から渡す
import Cairo from 'cairo';
import Pango from 'gi://Pango';
import PangoCairo from 'gi://PangoCairo';

export const BLUE = [0.21, 0.52, 0.89];
export const GREEN = [0.20, 0.82, 0.48];

export const AXIS_WIDTH = 34;
const LABEL_HEIGHT = 18;

function rgba(cr, [r, g, b], a = 1) {
    cr.setSourceRGBA(r, g, b, a);
}

function text(cr, font, str, x, y, align = 'left') {
    const layout = PangoCairo.create_layout(cr);
    layout.set_font_description(font);
    layout.set_text(str, -1);
    const [, logical] = layout.get_pixel_extents();
    const dx = align === 'right' ? -logical.width : align === 'center' ? -logical.width / 2 : 0;
    cr.moveTo(x + dx, y - logical.height / 2);
    PangoCairo.show_layout(cr, layout);
}

function roundedTop(cr, x, y, w, h, r) {
    r = Math.min(r, w / 2, h);
    cr.newSubPath();
    cr.moveTo(x, y + h);
    cr.lineTo(x, y + r);
    cr.arc(x + r, y + r, r, Math.PI, 1.5 * Math.PI);
    cr.arc(x + w - r, y + r, r, 1.5 * Math.PI, 2 * Math.PI);
    cr.lineTo(x + w, y + h);
    cr.closePath();
}

// opts.yFormat を省くと縦軸の目盛り文字を描かず、その分だけ描画域を広げる。
// 複数のグラフで横位置を揃えたいときは opts.axisWidth で余白を固定する
function frame(cr, width, height, opts) {
    const axisWidth = opts.axisWidth ?? (opts.yFormat ? AXIS_WIDTH : 0);
    const plot = {x: 0, y: 6, w: width - axisWidth, h: height - 6 - LABEL_HEIGHT};
    const font = opts.font.copy();
    font.set_absolute_size(opts.fontPx * Pango.SCALE);

    cr.setLineWidth(1);
    for (const tick of opts.yTicks) {
        const y = Math.round(plot.y + plot.h * (1 - tick / opts.yMax)) + 0.5;
        rgba(cr, opts.fg, tick === 0 ? 0.25 : 0.1);
        cr.setDash(tick === 0 ? [] : [2, 3], 0);
        cr.moveTo(plot.x, y);
        cr.lineTo(plot.x + plot.w, y);
        cr.stroke();
        if (opts.yFormat) {
            rgba(cr, opts.fg, 0.55);
            text(cr, font, opts.yFormat(tick), width, y, 'right');
        }
    }
    cr.setDash([], 0);

    const step = plot.w / opts.count;
    for (const {index, label} of opts.xLabels) {
        const x = plot.x + step * index;
        rgba(cr, opts.fg, 0.1);
        cr.moveTo(Math.round(x) + 0.5, plot.y);
        cr.lineTo(Math.round(x) + 0.5, plot.y + plot.h);
        cr.stroke();
        rgba(cr, opts.fg, 0.55);
        text(cr, font, label, x + 2, plot.y + plot.h + LABEL_HEIGHT / 2 + 1);
    }
    return {plot, step};
}

/**
 * values: [{value, accent}]（value が null の区間は描かない）
 * 戻り値の hitTest(x) でポインタ位置の区間番号を得る
 */
export function bars(cr, width, height, values, opts) {
    const {plot, step} = frame(cr, width, height, {...opts, count: values.length});
    const gap = step > 6 ? Math.max(1, step * 0.25) : step * 0.15;
    values.forEach((item, i) => {
        if (item.value === null)
            return;
        const h = Math.max(1.5, plot.h * Math.min(item.value, opts.yMax) / opts.yMax);
        const dim = opts.selected !== undefined && opts.selected !== null && opts.selected !== i;
        rgba(cr, item.accent ? GREEN : BLUE, dim ? 0.35 : 1);
        roundedTop(cr, plot.x + step * i + gap / 2, plot.y + plot.h - h, step - gap, h, 2.5);
        cr.fill();
    });
    return hitTester(plot, step, values.length);
}

/** values: [number|null]。null で線を切り、下をグラデーションで塗る */
export function area(cr, width, height, values, opts) {
    const {plot, step} = frame(cr, width, height, {...opts, count: values.length});
    const color = opts.color ?? BLUE;
    const segments = [];
    let current = [];
    values.forEach((v, i) => {
        if (v === null) {
            if (current.length)
                segments.push(current);
            current = [];
            return;
        }
        current.push([plot.x + step * (i + 0.5), plot.y + plot.h * (1 - Math.min(v, opts.yMax) / opts.yMax)]);
    });
    if (current.length)
        segments.push(current);

    const bottom = plot.y + plot.h;
    for (const pts of segments) {
        const gradient = new Cairo.LinearGradient(0, plot.y, 0, bottom);
        gradient.addColorStopRGBA(0, ...color, 0.45);
        gradient.addColorStopRGBA(1, ...color, 0.02);
        smoothPath(cr, pts);
        cr.lineTo(pts.at(-1)[0], bottom);
        cr.lineTo(pts[0][0], bottom);
        cr.closePath();
        cr.setSource(gradient);
        cr.fill();

        smoothPath(cr, pts);
        rgba(cr, color);
        cr.setLineWidth(2);
        cr.setLineJoin(Cairo.LineJoin.ROUND);
        cr.stroke();
    }
    if (opts.selected !== undefined && opts.selected !== null) {
        const x = plot.x + step * (opts.selected + 0.5);
        rgba(cr, opts.fg, 0.35);
        cr.setLineWidth(1);
        cr.moveTo(Math.round(x) + 0.5, plot.y);
        cr.lineTo(Math.round(x) + 0.5, bottom);
        cr.stroke();
    }
    return hitTester(plot, step, values.length);
}

// 隣り合う点の中点を通る2次ベジェで角を丸める
function smoothPath(cr, pts) {
    cr.newPath();
    cr.moveTo(...pts[0]);
    for (let i = 1; i < pts.length - 1; i++) {
        const [mx, my] = [(pts[i][0] + pts[i + 1][0]) / 2, (pts[i][1] + pts[i + 1][1]) / 2];
        const [x0, y0] = cr.getCurrentPoint();
        const [cx, cy] = pts[i];
        cr.curveTo(x0 + 2 / 3 * (cx - x0), y0 + 2 / 3 * (cy - y0),
            mx + 2 / 3 * (cx - mx), my + 2 / 3 * (cy - my), mx, my);
    }
    if (pts.length > 1)
        cr.lineTo(...pts.at(-1));
}

function hitTester(plot, step, count) {
    return x => {
        const i = Math.floor((x - plot.x) / step);
        return i >= 0 && i < count && x <= plot.x + plot.w ? i : null;
    };
}
