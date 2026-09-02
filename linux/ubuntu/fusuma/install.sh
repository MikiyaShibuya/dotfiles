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
#
# Build from source instead of using the apt package: apt ships v0.1.8, whose
# `key` subcommand takes key names (`alt+r`) rather than the raw
# `<keycode>:<pressed>` syntax config.yml relies on (`ydotool key 56:1 ...`).
# v0.1.8 silently treats `56:1` as an uninterpretable value and just delays,
# so gestures would break with no error. It also ships no ydotoold daemon.
YDOTOOL_VERSION=v1.0.4

if command -v ydotool &> /dev/null; then
    YDOTOOL_HELP="$(ydotool key --help 2>&1 || true)"
    if grep -q '<keycode>:<pressed>' <<< "$YDOTOOL_HELP"; then
        echo "ydotool is already installed: $(command -v ydotool)"
    else
        echo "Error: incompatible ydotool at $(command -v ydotool)"
        echo "  config.yml needs the v1.x raw keycode syntax (e.g. 'ydotool key 56:1')."
        echo "  Remove it (apt-get remove ydotool) and re-run this script."
        exit 1
    fi
else
    echo "Installing ydotool $YDOTOOL_VERSION from source..."
    apt-get update > /dev/null
    apt-get install -y --no-install-recommends \
        git cmake build-essential pkg-config scdoc > /dev/null

    if [[ ! -d /tmp/ydotool ]]; then
        git clone --depth 1 --branch "$YDOTOOL_VERSION" \
            https://github.com/ReimuNotMoe/ydotool /tmp/ydotool
    fi
    cmake -S /tmp/ydotool -B /tmp/ydotool/build > /dev/null
    cmake --build /tmp/ydotool/build > /dev/null
    cmake --install /tmp/ydotool/build > /dev/null
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
    echo "  systemctl --user enable --now ydotoold"
    echo "  systemctl --user enable --now fusuma"
fi

echo "Done! Fusuma installed."
echo "All config files are symlinked to dotfiles repo."
