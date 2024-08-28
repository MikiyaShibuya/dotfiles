#!/bin/bash

if [[ "$USE_DEBUG" == "1" ]]; then
    set -x
fi

if [[ `id -u` -ne 0 ]]; then
    echo Error: Run as ROOT
    exit 1
fi

if [[ -z "$USER" ]]; then
    echo Error: Run with USER=[user name]
    exit 1
fi

if [[ "$USER" = root ]]; then
    echo "Error: Run with USER=[user name], not root (e.g. sudo USER=\$USER ./install.sh)"
    exit 1
fi

# Exit when some error happened
set -e

# Determine OS
if [[ "$(uname)" = Darwin ]]; then
    OS='Mac'
    echo Installing for MacOS
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
    echo Installing for Linux
    MAJOR_VERSION=$(echo $(lsb_release -r) | sed -e 's/.*\ \([0-9]*\)\..*/\1/g')
else
    OS=''
fi

echo ========================================
echo OS: $OS
echo MAJOR_VERSION: $MAJOR_VERSION
echo ========================================

# Determine chip archtecture
if [[ "$(uname -m)" = x86_64 ]]; then
    ARCH='x86_64'
elif [[ "$(uname -m)" = arm64 ]]; then
    ARCH='arm64'
else
    ARCH=''
fi


#### Neovim Configuration ####

# Install neovim
if [[ $OS = Mac ]]; then

    echo Setting up diff-highlight
    shell/setup_diff_highlight.sh $USER

    brew install node
    brew install neovim
elif [[ $OS = Linux ]]; then

    apt-get update
    apt-get install --no-install-recommends -y \
        git build-essential curl tmux htop less \
        python3-pip iputils-ping software-properties-common \
        python3.10-venv

    echo Setting up diff-highlight
    shell/setup_diff_highlight.sh $USER

    su $USER -c "mkdir -p /home/$USER/.local"

    NODE_VERSION=20
    if (( MAJOR_VERSION <= 18 )); then
        NODE_VERSION=16
    fi
    echo "Installing NodeJS(${NODE_VERSION})"
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x \
        -o /tmp/nodesource_setup.sh
    bash /tmp/nodesource_setup.sh
    apt-get install --no-install-recommends -y nodejs
    su $USER -c "npm config set prefix ~/.local/"

    if [[ $ARCH = x86_64 ]]; then
        echo Installing neovim for x64-86
        if (( MAJOR_VERSION >= 22 )); then
            dpkg -i nvim/installer/neovim_v0.10.1-1-jammy_amd64.deb
        elif (( MAJOR_VERSION >= 20 )); then
            dpkg -i nvim/installer/neovim_v0.9.5-1-focal_amd64.deb
        else
            tar -C /tmp -xzf nvim/installer/nvim-linux64.tar.gz
            su $USER -c 'cp -r /tmp/nvim-linux64/bin /home/$USER/.local && \
              cp -r /tmp/nvim-linux64/lib /home/$USER/.local && \
              cp -r /tmp/nvim-linux64/share /home/$USER/.local && \
              cp -r /tmp/nvim-linux64/man/* /home/$USER/.local/man'
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


# Finally, conduct installation under user permission
su $USER -c "./as_user_install.sh"

# Use ~/.tmux.conf instead of  ~/.config/tmux/tmux.conf for Tmux < 3.1
apt-get satisfy "tmux (>= 3.1)" >& /dev/null \
    || su $USER -c "ln -nfs /home/$USER/.config/tmux/tmux.conf /home/$USER/.tmux.conf"
su $USER -c "~/.tmux/plugins/tpm/scripts/install_plugins.sh"
