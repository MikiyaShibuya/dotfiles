#!/bin/bash
#
# Install battery-power GNOME extension
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

EXT_UUID="battery-power@custom"
EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

echo "Installing $EXT_UUID extension..."

# Symlink extension directory
su "$USER" -c "mkdir -p '$USER_HOME/.local/share/gnome-shell/extensions'"
su "$USER" -c "ln -nfs '$SCRIPT_DIR' '$EXT_DIR'"

# Enable the extension.
# A running GNOME Shell does not rescan the extensions directory, so
# `gnome-extensions enable` fails for a newly added extension. Register the
# uuid in enabled-extensions directly so it comes up on the next login.
if ! su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gnome-extensions enable '$EXT_UUID'" 2>/dev/null; then
    current=$(su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings get org.gnome.shell enabled-extensions")
    if [[ "$current" != *"'$EXT_UUID'"* ]]; then
        if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
            updated="['$EXT_UUID']"
        else
            updated="${current%]}, '$EXT_UUID']"
        fi
        su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.shell enabled-extensions \"$updated\""
    fi
fi

echo "  Done."
echo "  NOTE: Log out and back in for the extension to take effect."
