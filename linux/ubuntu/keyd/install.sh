#!/bin/bash
set -euo pipefail

# Install keyd for Ubuntu
# Run with: sudo ./install.sh

if [[ $(id -u) -ne 0 ]]; then
    echo "Error: Run as root (sudo ./install.sh)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install keyd if not already installed
if command -v keyd &> /dev/null; then
    echo "keyd is already installed: $(keyd --version)"
else
    echo "Installing keyd..."
    apt-get update > /dev/null
    apt-get install -y --no-install-recommends git build-essential > /dev/null

    if [[ ! -d /tmp/keyd ]]; then
        git clone --depth 1 https://github.com/rvaiya/keyd /tmp/keyd
    fi
    cd /tmp/keyd
    make > /dev/null
    make install > /dev/null
fi

# Link configuration files
echo "Linking configuration files..."
mkdir -p /etc/keyd
ln -nfs "$SCRIPT_DIR/default.conf" /etc/keyd/default.conf

# Enable and start keyd service
echo "Enabling keyd service..."
systemctl enable keyd
systemctl restart keyd

# Install user config and keyd-application-mapper service
if [[ -n "${SUDO_USER:-}" ]]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
    USER_KEYD_DIR="$USER_HOME/.config/keyd"
    USER_SYSTEMD_DIR="$USER_HOME/.config/systemd/user"

    echo "Setting up user config for $SUDO_USER..."
    mkdir -p "$USER_KEYD_DIR"
    ln -nfs "$SCRIPT_DIR/app.conf" "$USER_KEYD_DIR/app.conf"
    chown -h "$SUDO_USER:$SUDO_USER" "$USER_KEYD_DIR/app.conf"

    echo "Linking keyd-application-mapper service..."
    mkdir -p "$USER_SYSTEMD_DIR"
    ln -nfs "$SCRIPT_DIR/keyd-application-mapper.service" "$USER_SYSTEMD_DIR/"
    chown -h "$SUDO_USER:$SUDO_USER" "$USER_SYSTEMD_DIR/keyd-application-mapper.service"

    echo "Run the following as your user to enable the application mapper:"
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable --now keyd-application-mapper"
fi

echo "Done! Keyd installed and running."
echo "All config files are symlinked to dotfiles repo."
