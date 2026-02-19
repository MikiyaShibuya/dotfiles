import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

// Tolerance in pixels for detecting tiled state
const TOLERANCE = 30;

export default class TileAcrossMonitorsExtension extends Extension {
    enable() {
        this._settings = this.getSettings();

        Main.wm.addKeybinding('tile-half-left',
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL,
            () => this._handleTile('left')
        );

        Main.wm.addKeybinding('tile-half-right',
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL,
            () => this._handleTile('right')
        );
    }

    _handleTile(direction) {
        const window = global.display.focus_window;
        if (!window || window.window_type !== Meta.WindowType.NORMAL)
            return;

        const monitorIndex = window.get_monitor();
        const workArea = this._getWorkArea(monitorIndex);
        const frame = window.get_frame_rect();

        if (this._isTiledTo(frame, workArea, direction)) {
            // Already tiled in this direction - move to next monitor
            const nextMonitor = this._getNextMonitor(monitorIndex, direction);
            if (nextMonitor !== null) {
                const nextWorkArea = this._getWorkArea(nextMonitor);
                // Tile to opposite side on new monitor (window "slides" across)
                const opposite = direction === 'left' ? 'right' : 'left';
                this._tileWindow(window, nextWorkArea, opposite, nextMonitor);
            }
        } else {
            // Tile on current monitor
            this._tileWindow(window, workArea, direction, monitorIndex);
        }
    }

    _getWorkArea(monitorIndex) {
        return global.workspace_manager
            .get_active_workspace()
            .get_work_area_for_monitor(monitorIndex);
    }

    _isTiledTo(frame, workArea, direction) {
        const halfWidth = Math.floor(workArea.width / 2);
        const heightMatch = Math.abs(frame.height - workArea.height) < TOLERANCE;
        const widthMatch = Math.abs(frame.width - halfWidth) < TOLERANCE;

        if (!heightMatch || !widthMatch)
            return false;

        if (direction === 'left')
            return Math.abs(frame.x - workArea.x) < TOLERANCE;
        else
            return Math.abs(frame.x - (workArea.x + halfWidth)) < TOLERANCE;
    }

    _tileWindow(window, workArea, direction, monitorIndex) {
        if (window.maximized_horizontally || window.maximized_vertically)
            window.unmaximize(Meta.MaximizeFlags.BOTH);

        const halfWidth = Math.floor(workArea.width / 2);
        const x = direction === 'left' ? workArea.x : workArea.x + halfWidth;

        window.move_to_monitor(monitorIndex);
        window.move_resize_frame(true, x, workArea.y, halfWidth, workArea.height);
    }

    _getNextMonitor(currentIndex, direction) {
        const nMonitors = global.display.get_n_monitors();
        if (nMonitors <= 1)
            return null;

        const currentGeo = global.display.get_monitor_geometry(currentIndex);
        let candidates = [];

        for (let i = 0; i < nMonitors; i++) {
            if (i === currentIndex)
                continue;
            const geo = global.display.get_monitor_geometry(i);
            if (direction === 'right' && geo.x > currentGeo.x)
                candidates.push({index: i, x: geo.x});
            else if (direction === 'left' && geo.x < currentGeo.x)
                candidates.push({index: i, x: geo.x});
        }

        if (candidates.length === 0) {
            // Wrap around: pick the furthest monitor in the opposite direction
            for (let i = 0; i < nMonitors; i++) {
                if (i === currentIndex)
                    continue;
                const geo = global.display.get_monitor_geometry(i);
                candidates.push({index: i, x: geo.x});
            }
            if (candidates.length === 0)
                return null;
            // Right wraps to leftmost, left wraps to rightmost
            candidates.sort((a, b) =>
                direction === 'right' ? a.x - b.x : b.x - a.x
            );
            return candidates[0].index;
        }

        // Pick the closest monitor in the given direction
        candidates.sort((a, b) =>
            direction === 'right' ? a.x - b.x : b.x - a.x
        );
        return candidates[0].index;
    }

    disable() {
        Main.wm.removeKeybinding('tile-half-left');
        Main.wm.removeKeybinding('tile-half-right');
        this._settings = null;
    }
}
