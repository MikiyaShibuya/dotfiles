#!/bin/bash

if [[ `id -u` -ne 0 || -z "$USER" ]]; then
    echo Run as ROOT with USER=[user name]
    exit 1
fi

# Exit when some error happened
set -e

# Determine OS
if [ "$(uname)" = 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
else
    OS=''
fi


USER_HOME=$(eval echo ~$USER)
su $USER -c "mkdir -p $USER_HOME/.local/bin"
if [ "$OS" = 'Mac' ]; then
    DIFF_HIGHLIGHT_DIR=/opt/homebrew/share/git-core/contrib/diff-highlight
    if [ ! -f $DIFF_HIGHLIGHT_DIR/diff-highlight ]; then
        echo "There is no diff-highlight, installing..."
        su $USER -c 'brew install git'
    fi
    su $USER -c 'ln -nfs $DIFF_HIGHLIGHT_DIR/diff-highlight ~/.local/bin'
elif [ "$OS" = 'Linux' ]; then
    # Install diff-highlight if there is no binary
    DIFF_HIGHLIGHT_DIR=/usr/share/doc/git/contrib/diff-highlight
    if [ ! -f $DIFF_HIGHLIGHT_DIR/diff-highlight ]; then
        echo "No diff-highlight installed"
        if [ ! -f $DIFF_HIGHLIGHT_DIR/Makefile ]; then
            echo "No diff-highlight files, cloning"
            git clone --depth 1 https://github.com/git/git.git /tmp/git
            cp -r /tmp/git/contrib/diff-highlight/* $DIFF_HIGHLIGHT_DIR
        fi
        cd $DIFF_HIGHLIGHT_DIR
        make
        cd -
    fi
    su $USER -c 'ln -nfs /usr/share/doc/git/contrib/diff-highlight/diff-highlight $USER_HOME/.local/bin'
    chmod +x $USER_HOME/.local/bin/diff-highlight
fi
