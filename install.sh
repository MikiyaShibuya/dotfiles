#!/bin/bash

if [ "$(uname)" = 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
else
    OS=''
fi

# config for vim
ln -nfs $PWD/vimrc $HOME/.vimrc

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -nfs $PWD/nvim/init.vim $HOME/.config/nvim/init.vim

# git, tmux, zshrc setting
ln -nfs $PWD/shell/gitconfig $HOME/.gitconfig
ln -nfs $PWD/tmux/tmux.conf $HOME/.tmux.conf
ln -nfs $PWD/shell/zshrc $HOME/.zshrc
if [ $OS = 'Mac' ]; then
    ln -nfs $PWD/shell/p10k_mac.zsh $HOME/.p10k.zsh
elif [ $OS = 'Linux' ]; then
    ln -nfs $PWD/shell/p10k_ubuntu.zsh $HOME/.p10k.zsh
fi

# dein & coc settings for nvim
ln -nfs $PWD/nvim/dein.toml $HOME/.config/nvim/
ln -nfs $PWD/nvim/dein_lazy.toml $HOME/.config/nvim/
ln -nfs $PWD/nvim/coc-settings.json $HOME/.config/nvim/
ln -nfs $PWD/nvim/coc-hook-add.vim $HOME/.config/nvim/

# Dein installation
if [ ! -d "$HOME/.cache/dein" ]
then
    echo "Dein have not been initialized. Installing..."
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > /tmp/installer.sh
    sh /tmp/installer.sh ~/.cache/dein
    echo "Dein installation complete."
fi

# Install powerlevel10k if it is not exist
if [ ! -d "$HOME/powerlevel10k" ]
then
    echo "powerlevel10k have not been initialized. Installing..."
    git clone --depth 1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    echo "powerlevel10k installation complete."
fi

# Install fzf if it is not exist
if [ ! -d "$HOME/.fzf" ]
then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    yes | ~/.fzf/install
fi

# Install tqm, tmux plugin manager
if [ ! -e $HOME/.tmux ];then
    mkdir -p $HOME/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi

# Install pyenv
if [ ! -d "$HOME/.pyenv" ]
then
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
fi

