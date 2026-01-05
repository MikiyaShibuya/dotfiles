#!/bin/bash
set -euo pipefail

# Install backlight control for Ubuntu
# Fixes brightness reset to 100% on resume from suspend (Ubuntu 24.04 bug)
# Run with: sudo ./install.sh

if [[ $(id -u) -ne 0 ]]; then
    echo "Error: Run as root (sudo ./install.sh)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Link monitor-unlock script
echo "Linking monitor-unlock.sh..."
ln -nfs "$SCRIPT_DIR/monitor-unlock.sh" /usr/local/bin/monitor-unlock.sh
chmod +x /usr/local/bin/monitor-unlock.sh

# Link systemd service
echo "Linking monitor-unlock.service..."
ln -nfs "$SCRIPT_DIR/monitor-unlock.service" /etc/systemd/system/monitor-unlock.service

# Create log file with proper permissions
touch /var/log/reset_backlight_when_unlock.log
chmod 666 /var/log/reset_backlight_when_unlock.log

# Enable and start service
echo "Enabling monitor-unlock service..."
systemctl daemon-reload
systemctl enable monitor-unlock.service
systemctl restart monitor-unlock.service

echo "Done! Backlight control installed and running."
echo "All config files are symlinked to dotfiles repo."
