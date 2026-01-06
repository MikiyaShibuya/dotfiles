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
unlink $USER_HOME/.config/nvim/init.lua
unlink $USER_HOME/.config/nvim/lua

