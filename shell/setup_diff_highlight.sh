#!/bin/bash
#
# Determine OS
if [ "$(uname)" = 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
else
    OS=''
fi

mkdir -p $HOME/.local/bin
ln -nfs $PWD/shell/gitconfig $HOME/.gitconfig
if [ "$OS" = 'Mac' ]; then
    ln -nfs /opt/homebrew/share/git-core/contrib/diff-highlight/diff-highlight $HOME/.local/bin
elif [ "$OS" = 'Linux' ]; then
    # Install diff-highlight if there is no binary
    DIFF_HIGHLIGHT_DIR=/usr/share/doc/git/contrib/diff-highlight
    if [ ! -f $DIFF_HIGHLIGHT_DIR/diff-highlight ]; then
        echo "No diff-highlight installed"
        if [ ! -f $DIFF_HIGHLIGHT_DIR/Makefile ]; then
            echo "No diff-highlight files, cloning"
            git clone --depth 1 https://github.com/git/git.git /tmp/git
            sudo cp -r /tmp/git/contrib/diff-highlight/* $DIFF_HIGHLIGHT_DIR
        fi
        cd $DIFF_HIGHLIGHT_DIR
        sudo make
        cd -
    fi
    ln -nfs /usr/share/doc/git/contrib/diff-highlight/diff-highlight $HOME/.local/bin
    sudo chmod +x $HOME/.local/bin/diff-highlight
fi
