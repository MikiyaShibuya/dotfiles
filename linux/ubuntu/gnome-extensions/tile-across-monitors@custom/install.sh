#!/bin/bash
#
# Install tile-across-monitors GNOME extension
#
# Usage: sudo ./install.sh
#   Expects $USER to be set to the target user (via SUDO_USER or explicitly)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "${USER:-}" || "$USER" == "root" ]]; then
    if [[ -n "${SUDO_USER:-}" ]]; then
        USER="$SUDO_USER"
    else
        echo "Error: Could not determine target user."
        exit 1
    fi
fi

USER_HOME=$(eval echo ~"$USER")
USER_ID=$(id -u "$USER")
DBUS_ADDR="unix:path=/run/user/${USER_ID}/bus"

EXT_UUID="tile-across-monitors@custom"
EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

echo "Installing $EXT_UUID extension..."

# Symlink extension directory
su "$USER" -c "mkdir -p '$USER_HOME/.local/share/gnome-shell/extensions'"
su "$USER" -c "ln -nfs '$SCRIPT_DIR' '$EXT_DIR'"

# Compile schemas
glib-compile-schemas "$SCRIPT_DIR/schemas/"

# Clear tiling-assistant's left/right keybindings to avoid conflicts
su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.shell.extensions.tiling-assistant tile-left-half '[]'" 2>/dev/null || true
su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.shell.extensions.tiling-assistant tile-right-half '[]'" 2>/dev/null || true

# Enable the extension
su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gnome-extensions enable '$EXT_UUID'" 2>/dev/null || true

echo "  Done."
echo "  NOTE: Log out and back in for the extension to take effect."
