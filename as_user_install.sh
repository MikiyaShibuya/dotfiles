#!/bin/bash

if [[ `id -u` == 0 ]]; then
    echo Error: Run as NON-ROOT user
    exit 1
fi

if [[ "$USER" == root ]]; then
    echo Error: Run as NON-ROOT user
    exit 1
fi


# Exit when some error happened
set -e

# Determine OS
if [[ "$(uname)" = Darwin ]]; then
    OS='Mac'
    echo Installing for MacOS
elif [[ "$(expr substr $(uname -s) 1 5)" = Linux ]]; then
    OS='Linux'
    echo Installing for Linux
else
    OS=''
fi

# Setup gitconfig and diff-highlight
ln -nfs $PWD/shell/gitconfig $HOME/.gitconfig


# Install tmux and zsh settigns
mkdir -p $HOME/.config/tmux
ln -nfs $PWD/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
ln -nfs $PWD/shell/zshrc $HOME/.zshrc

# # Dein installation
# if [ ! -d "$HOME/.cache/dein" ]
# then
#     echo "Dein have not been initialized. Installing..."
#     curl https://raw.githubusercontent.com/Shougo/dein-installer.vim/main/installer.sh > /tmp/installer.sh
#     mkdir -p $HOME/.cache
#     sh /tmp/installer.sh $HOME/.cache/dein --use-neovim-config
#     echo "Dein installation complete."
# fi

# Configure nvim
mkdir -p  $HOME/.config/nvim
# ln -nfs $PWD/nvim/init.vim $HOME/.config/nvim/init.vim
ln -nfs $PWD/nvim/init.lua $HOME/.config/nvim/init.lua

# dein & coc settings for nvim
# ln -nfs $PWD/nvim/dein.toml $HOME/.config/nvim/
# ln -nfs $PWD/nvim/dein_lazy.toml $HOME/.config/nvim/
# ln -nfs $PWD/nvim/coc-settings.json $HOME/.config/nvim/
# ln -nfs $PWD/nvim/coc-hook-add.vim $HOME/.config/nvim/


# Install fzf if it is not exist
if [ ! -d "$HOME/.fzf" ]
then
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
    yes | $HOME/.fzf/install
fi


# Install powerlevel10k
if [[ $OS = Mac ]]; then
    ln -nfs $PWD/shell/p10k_mac.zsh $HOME/.p10k.zsh
elif [[ $OS = Linux ]]; then
    ln -nfs $PWD/shell/p10k_ubuntu.zsh $HOME/.p10k.zsh
fi

if [[ ! -d "$HOME/powerlevel10k" ]]; then
    echo "powerlevel10k have not been initialized. Installing..."
    git clone --depth 1 https://github.com/romkatv/powerlevel10k.git $HOME/powerlevel10k
    echo "powerlevel10k installation complete."
fi


# Install tqm, tmux plugin manager
if [[ ! -e $HOME/.tmux ]];then
    mkdir -p $HOME/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi


# Install pyenv
if [[ ! -d "$HOME/.pyenv" ]]
then
    git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
fi

PIP_INSTALL_CMD="pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"
python3 -m $PIP_INSTALL_CMD --upgrade pip
python3 -m $PIP_INSTALL_CMD setuptools
python3 -m $PIP_INSTALL_CMD neovim
