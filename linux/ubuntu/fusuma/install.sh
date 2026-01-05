#!/bin/bash
set -euo pipefail

# Install fusuma for Ubuntu
# Run with: sudo ./install.sh

if [[ $(id -u) -ne 0 ]]; then
    echo "Error: Run as root (sudo ./install.sh)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install fusuma if not already installed
if command -v fusuma &> /dev/null; then
    echo "fusuma is already installed: $(fusuma --version)"
else
    echo "Installing fusuma and dependencies..."
    apt-get update > /dev/null
    apt-get install -y --no-install-recommends \
        ruby ruby-dev build-essential libevdev-dev > /dev/null

    gem install fusuma
fi

# Install ydotool if not already installed
if command -v ydotool &> /dev/null; then
    echo "ydotool is already installed"
else
    echo "Installing ydotool..."
    apt-get install -y --no-install-recommends ydotool > /dev/null
fi

# Setup uinput access
echo "Setting up uinput access..."
ln -nfs "$SCRIPT_DIR/99-uinput.rules" /etc/udev/rules.d/99-uinput.rules
udevadm control --reload-rules
udevadm trigger

# Add user to input group
if [[ -n "${SUDO_USER:-}" ]]; then
    if ! groups "$SUDO_USER" | grep -q '\binput\b'; then
        echo "Adding $SUDO_USER to input group..."
        usermod -aG input "$SUDO_USER"
        echo "NOTE: Log out and back in for group change to take effect"
    fi

    USER_HOME=$(eval echo ~$SUDO_USER)
    USER_CONFIG_DIR="$USER_HOME/.config/fusuma"
    USER_SYSTEMD_DIR="$USER_HOME/.config/systemd/user"

    # Link fusuma config
    echo "Linking fusuma config for $SUDO_USER..."
    mkdir -p "$USER_CONFIG_DIR"
    ln -nfs "$SCRIPT_DIR/config.yml" "$USER_CONFIG_DIR/config.yml"
    chown -h "$SUDO_USER:$SUDO_USER" "$USER_CONFIG_DIR/config.yml"

    # Link systemd user service
    echo "Linking fusuma service..."
    mkdir -p "$USER_SYSTEMD_DIR"
    ln -nfs "$SCRIPT_DIR/fusuma.service" "$USER_SYSTEMD_DIR/"
    chown -h "$SUDO_USER:$SUDO_USER" "$USER_SYSTEMD_DIR/fusuma.service"

    echo "Run the following as your user to enable fusuma:"
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable --now fusuma"
fi

echo "Done! Fusuma installed."
echo "All config files are symlinked to dotfiles repo."
