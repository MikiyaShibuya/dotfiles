#!/bin/bash

# Determine OS
if [ "$(uname)" = 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
else
    OS=''
fi

USER_HOME=$(eval echo ~$USER)
unlink $USER_HOME/.gitconfig
unlink $USER_HOME/.tmux.conf
unlink $USER_HOME/.zshrc

if [ $OS = 'Mac' ]; then
    unlink $USER_HOME/.p10k.zsh
elif [ $OS = 'Linux' ]; then
    unlink $USER_HOME/.p10k.zsh
fi

unlink $USER_HOME/.config/nvim/init.vim
unlink $USER_HOME/.config/nvim/dein.toml
unlink $USER_HOME/.config/nvim/dein_lazy.toml
unlink $USER_HOME/.config/nvim/coc-settings.json
unlink $USER_HOME/.config/nvim/coc-hook-add.vim
