#!/bin/bash

# Override home directory
if [ "$1" = "--skip-sudo" ]; then
    SKIP_SUDO=true
fi

# Determine OS
if [ "$(uname)" = 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
else
    OS=''
fi

# Determine chip archtecture
if [ "$(uname -m)" = 'x86_64' ]; then
    ARCH='x86_64'
elif [ "$(uname -m)" = 'arm64' ]; then
    ARCH='arm64'
else
    ARCH=''
fi


# Setup gitconfig and diff-highlight
ln -nfs $PWD/shell/gitconfig $HOME/.gitconfig
if [ -z $SKIP_SUDO ]; then
    sudo shell/setup_diff_highlight.sh ~
fi

ln -nfs $PWD/tmux/tmux.conf $HOME/.tmux.conf
ln -nfs $PWD/shell/zshrc $HOME/.zshrc
if [ $OS = 'Mac' ]; then
    ln -nfs $PWD/shell/p10k_mac.zsh $HOME/.p10k.zsh
elif [ $OS = 'Linux' ]; then
    ln -nfs $PWD/shell/p10k_ubuntu.zsh $HOME/.p10k.zsh
fi


#### Neovim Configuration ####

# Install neovim
if [ $OS = 'Mac' ]; then
    brew install neovim
    brew install node
elif [ $OS = 'Linux' ]; then
    if [ $ARCH = 'x86_64' ]; then
        if [ -z $SKIP_SUDO ]; then
            sudo dpkg -i nvim/installer/neovim_v0.9.5-dev-g130bfe22c_amd64.deb
        fi
    else
        echo "========"
        echo ""
        echo "    Currently, neovim is not installed automatically for $ARCH archtecture."
        echo "    Please install neovim manually."
        echo ""
        echo "========"
    fi
fi

# Dein installation
if [ ! -d "$HOME/.cache/dein" ]
then
    echo "Dein have not been initialized. Installing..."
    curl https://raw.githubusercontent.com/Shougo/dein-installer.vim/main/installer.sh > /tmp/installer.sh
    sh /tmp/installer.sh $HOME/.cache/dein --use-neovim-config
    echo "Dein installation complete."
fi

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -nfs $PWD/nvim/init.vim $HOME/.config/nvim/init.vim

# dein & coc settings for nvim
ln -nfs $PWD/nvim/dein.toml $HOME/.config/nvim/
ln -nfs $PWD/nvim/dein_lazy.toml $HOME/.config/nvim/
ln -nfs $PWD/nvim/coc-settings.json $HOME/.config/nvim/
ln -nfs $PWD/nvim/coc-hook-add.vim $HOME/.config/nvim/


#### Zsh Configuration ####

# Install powerlevel10k if it is not exist
if [ ! -d "$HOME/powerlevel10k" ]
then
    echo "powerlevel10k have not been initialized. Installing..."
    git clone --depth 1 https://github.com/romkatv/powerlevel10k.git $HOME/powerlevel10k
    echo "powerlevel10k installation complete."
fi

# Install fzf if it is not exist
if [ ! -d "$HOME/.fzf" ]
then
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
    yes | $HOME/.fzf/install
fi


#### Tmux Configuration ####

# Install tqm, tmux plugin manager
if [ ! -e $HOME/.tmux ];then
    mkdir -p $HOME/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi


## Pyenv Configuration ####

# Install pyenv
if [ ! -d "$HOME/.pyenv" ]
then
    git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
fi

python3 -m pip install neovim
