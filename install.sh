#!/bin/bash

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

if [[ "${USE_DEBUG:-}" == "1" ]]; then
    set -x
fi

if [[ `id -u` -ne 0 ]]; then
    echo Error: Run as ROOT
    exit 1
fi

if [[ -z "${USER:-}" ]]; then
    echo Error: Run with USER=[user name]
    exit 1
fi

if [[ "$USER" = root ]]; then
    echo "Error: Run with USER=[user name], not root (e.g. sudo USER=\$USER ./install.sh)"
    exit 1
fi

# Determine OS
if [[ "$(uname)" = Darwin ]]; then
    OS='Mac'
    echo Installing for MacOS
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
    echo Installing for Linux
    . /etc/os-release
    DISTRO=$ID
    MAJOR_VERSION=$(echo $VERSION_ID | cut -d '.' -f 1)
else
    echo "Error: Unsupported OS: $(uname)"
    exit 1
fi

echo ========================================
echo OS: $OS
[[ -n "${DISTRO:-}" ]] && echo DISTRO: $DISTRO
[[ -n "${MAJOR_VERSION:-}" ]] && echo MAJOR_VERSION: $MAJOR_VERSION
echo ========================================

# Determine chip archtecture
if [[ "$(uname -m)" = x86_64 ]]; then
    ARCH='x86_64'
elif [[ "$(uname -m)" = arm64 ]]; then
    ARCH='arm64'
elif [[ "$(uname -m)" = aarch64 ]]; then
    ARCH='arm64'
else
    echo "Error: Unsupported architecture: $(uname -m)"
    exit 1
fi


#### Neovim Configuration ####

# Install neovim
if [[ $OS = Mac ]]; then
    echo "Installing neovim"
    su $USER -c "brew install node"
    su $USER -c "brew install neovim"


elif [[ $OS = Linux ]]; then
    echo "Installing requirements"
    apt-get update > /dev/null
    apt-get install --no-install-recommends -y \
        git build-essential curl unzip tmux htop less zsh \
        python3-pip python3-venv iputils-ping software-properties-common \
        > /dev/null

    su $USER -c 'mkdir -p $HOME/.local/bin'

    # Install fnm (Fast Node Manager) and Node.js
    echo "Installing fnm and NodeJS"
    su $USER -c 'if [[ ! -d "$HOME/.local/share/fnm" ]]; then curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell; fi'
    su $USER -c 'export PATH="$HOME/.local/share/fnm:$PATH" && eval "$(fnm env)" && fnm install 22 && fnm default 22'

    if command -v nvim &>/dev/null; then
        echo "neovim is already installed: $(nvim --version | head -1)"
    elif [[ $ARCH = x86_64 ]]; then
        echo Installing neovim for x64-86
        if (( MAJOR_VERSION >= 24 )); then
            dpkg -i nvim/installer/neovim_v0.11.2-1-noble_amd64.deb
        elif (( MAJOR_VERSION >= 22 )); then
            dpkg -i nvim/installer/neovim_v0.11.2-1-jammy_amd64.deb
        elif (( MAJOR_VERSION >= 20 )); then
            dpkg -i nvim/installer/neovim_v0.11.2-1-focal_amd64.deb
        else
            tar -C /tmp -xzf nvim/installer/nvim-linux64.tar.gz
            su $USER -c 'cp -r /tmp/nvim-linux64/bin $HOME/.local && \
              cp -r /tmp/nvim-linux64/lib $HOME/.local && \
              cp -r /tmp/nvim-linux64/share $HOME/.local && \
              cp -r /tmp/nvim-linux64/man/* $HOME/.local/man'
        fi
    else
        if (( MAJOR_VERSION >= 22 )); then
            echo Installing neovim for arm64 jammy
            dpkg -i nvim/installer/neovim_v0.10.1-1-jammy_arm64.deb
        elif (( MAJOR_VERSION >= 20 )); then
            echo Installing neovim for arm64 focal
            dpkg -i nvim/installer/neovim_v0.9.5-1-focal_arm64.deb
        else
            echo Installing neovim older than focal for arm64 is not supported
            sleep 5
        fi
    fi
fi

# Install diff-highlight if not installed
shell/setup_diff_highlight.sh

# Installation under user permission
su $USER -c "./as_user_install.sh"

# Use ~/.tmux.conf instead of  ~/.config/tmux/tmux.conf for Tmux < 3.1
USER_HOME=$(eval echo ~$USER)
apt-get satisfy "tmux (>= 3.1)" >& /dev/null \
    || su $USER -c "ln -nfs $USER_HOME/.config/tmux/tmux.conf $USER_HOME/.tmux.conf"
su $USER -c "~/.tmux/plugins/tpm/scripts/install_plugins.sh"
