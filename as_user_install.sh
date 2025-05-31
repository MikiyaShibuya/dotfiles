#!/bin/bash

if [[ "$USE_DEBUG" == "1" ]]; then
    set -x
fi

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

# Link gitconfig
# ln -nfs $PWD/shell/gitconfig $HOME/.gitconfig
touch $HOME/.gitconfig
grep -q "Custom preference" $HOME/.gitconfig || cat shell/gitconfig >> $HOME/.gitconfig

# Configure nvim
mkdir -p  $HOME/.config/nvim
ln -nfs $PWD/nvim/init.lua $HOME/.config/nvim/init.lua
ln -nfs $PWD/nvim/lua $HOME/.config/nvim/lua
nvim --headless "+Lazy! sync" +qa | true


# ==== ZSH Setting ====
ln -nfs $PWD/shell/zshrc $HOME/.zshrc

# Install fzf if it is not exist
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
    yes | $HOME/.fzf/install
fi
# Place zsh setup it not yet
if [ ! -f "$HOME/.fzf.zsh" ]; then
    yes | zsh -c "$HOME/.fzf/install"
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
    export XDG_CACHE_HOME=$HOME/.cache/p10k
    $HOME/powerlevel10k/gitstatus/install
    echo "powerlevel10k installation complete."
fi

mkdir -p $HOME/.zsh
if [ ! -d "$HOME/.zsh/zsh-autosuggestions" ]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
fi


# ==== TMUX Setting ====
mkdir -p $HOME/.config/tmux
ln -nfs $PWD/tmux/tmux.conf $HOME/.config/tmux/tmux.conf

# Install tqm (tmux plugin manager)
if [[ ! -e $HOME/.tmux ]];then
    mkdir -p $HOME/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi


# Install pyenv
if [[ ! -d "$HOME/.pyenv" ]]
then
    git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
fi

if [[ $OS = Mac ]]; then
    defaults write -g InitialKeyRepeat -int 11 # 15ms x 11 = 165ms
    defaults write -g KeyRepeat -int 1 # 15ms x 1 = 15ms
fi

export PIP_BREAK_SYSTEM_PACKAGES=1
PIP_INSTALL_CMD="pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"
python3 -m $PIP_INSTALL_CMD --upgrade pip
python3 -m $PIP_INSTALL_CMD setuptools
python3 -m $PIP_INSTALL_CMD neovim
