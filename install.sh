#!/bin/bash

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
else
    OS=''
fi

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
elif [[ $OS = Linux && $ARCH = x86_64 ]]; then

    apt-get update
    apt-get install --no-install-recommends -y \
        git build-essential curl tmux htop less \
        python3-pip iputils-ping software-properties-common

    echo Setting up diff-highlight
    shell/setup_diff_highlight.sh $USER

    su $USER -c "mkdir -p /home/$USER/.local"

    curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh
    bash /tmp/nodesource_setup.sh
    apt-get install --no-install-recommends -y nodejs
    su $USER -c "npm config set prefix ~/.local/"

    echo Installing neovim for x64-86
    tar -C /tmp -xzf nvim/installer/nvim-linux64.tar.gz
    su $USER -c 'cp -r /tmp/nvim-linux64/bin /home/$USER/.local && \
      cp -r /tmp/nvim-linux64/lib /home/$USER/.local && \
      cp -r /tmp/nvim-linux64/share /home/$USER/.local && \
      cp -r /tmp/nvim-linux64/man/* /home/$USER/.local/man'
else
    echo "========"
    echo ""
    echo "    Currently, neovim is not installed automatically for $ARCH archtecture."
    echo "    Please install neovim manually."
    echo ""
    echo "========"
fi


# Finally, conduct installation under user permission
su $USER -c "./install_as_user.sh"

