#!/bin/bash
#
# setup_diff_highlight.sh - Install diff-highlight for git
#
# Usage: Called from install.sh (requires root)
#
# This script installs diff-highlight, which provides word-level diff
# highlighting for git. On macOS it uses Homebrew, on Linux it builds
# from source if needed.
#

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    echo "Error: Run with sudo"
    exit 1
fi

# Use SUDO_USER if USER is not set or is root
if [[ -n "${SUDO_USER:-}" && ( -z "${USER:-}" || "${USER:-}" == "root" ) ]]; then
    USER="$SUDO_USER"
fi

if [[ -z "${USER:-}" || "$USER" == "root" ]]; then
    echo "Error: Could not determine target user"
    exit 1
fi

# Determine OS
if [[ "$(uname)" = Darwin ]]; then
    OS='Mac'
elif [[ "$(expr substr $(uname -s) 1 5)" = Linux ]]; then
    OS='Linux'
else
    OS=''
fi


USER_HOME=$(eval echo ~"$USER")
su "$USER" -c "mkdir -p '$USER_HOME/.local/bin'"

if [[ "$OS" = Mac ]]; then
    DIFF_HIGHLIGHT_DIR=/opt/homebrew/share/git-core/contrib/diff-highlight
    if [[ ! -f "$DIFF_HIGHLIGHT_DIR/diff-highlight" ]]; then
        echo "Installing diff-highlight..."
        su "$USER" -c 'brew install git'
    else
        echo "diff-highlight already installed"
    fi
    su "$USER" -c "ln -nfs '$DIFF_HIGHLIGHT_DIR/diff-highlight' '$USER_HOME/.local/bin'"

elif [[ "$OS" = Linux ]]; then
    # Install diff-highlight if there is no binary
    DIFF_HIGHLIGHT_DIR=/usr/share/doc/git/contrib/diff-highlight
    if [[ ! -f "$DIFF_HIGHLIGHT_DIR/diff-highlight" ]]; then
        echo "Installing diff-highlight..."
        if [[ ! -f "$DIFF_HIGHLIGHT_DIR/Makefile" ]]; then
            rm -rf /tmp/git
            git clone -q --depth 1 https://github.com/git/git.git /tmp/git
            mkdir -p "$DIFF_HIGHLIGHT_DIR"
            cp -r /tmp/git/contrib/diff-highlight/* "$DIFF_HIGHLIGHT_DIR"
        fi
        pushd "$DIFF_HIGHLIGHT_DIR" > /dev/null
        make > /dev/null
        popd > /dev/null
    else
        echo "diff-highlight already installed"
    fi
    su "$USER" -c "ln -nfs '$DIFF_HIGHLIGHT_DIR/diff-highlight' '$USER_HOME/.local/bin'"
    chmod +x "$USER_HOME/.local/bin/diff-highlight"
fi
