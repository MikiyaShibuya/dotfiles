# Tile Across Monitors

GNOME Shell extension that tiles windows to half screen and moves them across monitors when already tiled to the edge.

## Behavior

| State | Key | Result |
|-------|-----|--------|
| Not tiled | Super+Left | Tile to left half |
| Not tiled | Super+Right | Tile to right half |
| Tiled left | Super+Left | Move to left monitor, tile right |
| Tiled right | Super+Right | Move to right monitor, tile left |
| Rightmost monitor, tiled right | Super+Right | Wrap to leftmost monitor, tile left |
| Leftmost monitor, tiled left | Super+Left | Wrap to rightmost monitor, tile right |

## Requirements

- GNOME Shell 46
- `tiling-assistant` の `tile-left-half` / `tile-right-half` キーバインドをクリアすること（競合回避）

## Install

```bash
sudo ./install.sh
```

Or via `install_optional.sh` (component: `tile_across_monitors`).

Log out and back in after installation.
