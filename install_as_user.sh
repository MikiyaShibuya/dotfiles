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

# Configure nvim
mkdir -p  $HOME/.config
ln -nfs $PWD/new_nvim $HOME/.config/nvim


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

python3 -m pip install neovim