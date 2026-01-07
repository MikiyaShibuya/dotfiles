#!/bin/bash

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

if [[ "${USE_DEBUG:-}" == "1" ]]; then
    set -x
fi

if [[ $(id -u) == 0 ]]; then
    echo Error: Run as NON-ROOT user
    exit 1
fi

if [[ "${USER:-}" == root ]]; then
    echo Error: Run as NON-ROOT user
    exit 1
fi

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

# Insert custom config into .gitconfig if not yet
grep -q "Custom preference" $HOME/.gitconfig &> /dev/null || \
  cat ./shell/gitconfig >> $HOME/.gitconfig

# Configure nvim
mkdir -p  $HOME/.config/nvim
ln -nfs $PWD/nvim/init.lua $HOME/.config/nvim/init.lua
ln -nfs $PWD/nvim/lua $HOME/.config/nvim/lua
nvim --headless "+Lazy! sync" +qa &> /dev/null || true


# ==== ZSH Setting ====

# Install zsh
if [[ -h $HOME/.zshrc ]]; then
  unlink $HOME/.zshrc
  touch $HOME/.zshrc
fi

SOURCE_LINE="source $PWD/shell/zshrc"
ZSHRC_PATH="$HOME/.zshrc"
if ! grep -qxF "$SOURCE_LINE" $ZSHRC_PATH; then
  echo "# ======== Include dotfiles config ========" >> $ZSHRC_PATH
  echo $SOURCE_LINE >> $ZSHRC_PATH
  echo "# ========" >> $ZSHRC_PATH
  echo "" >> $ZSHRC_PATH
fi
zsh $HOME/.zshrc



# ==== TMUX Setting ====
mkdir -p $HOME/.config/tmux
ln -nfs $PWD/tmux/tmux.conf $HOME/.config/tmux/tmux.conf

# ==== WezTerm Setting ====
mkdir -p $HOME/.config/wezterm
ln -nfs $PWD/wezterm/wezterm.lua $HOME/.config/wezterm/wezterm.lua

# ==== Claude Code Setting ====
mkdir -p $HOME/.claude
ln -nfs $PWD/claude/settings.json $HOME/.claude/settings.json
ln -nfs $PWD/claude/CLAUDE.md $HOME/.claude/CLAUDE.md

# Install tqm (tmux plugin manager)
if [[ ! -e $HOME/.tmux ]];then
    mkdir -p $HOME/.tmux/plugins
    git clone -q --depth 1 https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi


# ==== pyenv ====
if [[ ! -d "$HOME/.pyenv" ]]
then
    git clone -q --depth 1 https://github.com/pyenv/pyenv.git $HOME/.pyenv
fi

if [[ $OS = Mac ]]; then
    defaults write -g InitialKeyRepeat -int 11 # 15ms x 11 = 165ms
    defaults write -g KeyRepeat -int 1 # 15ms x 1 = 15ms
fi

export PIP_BREAK_SYSTEM_PACKAGES=1
PIP_INSTALL_CMD="pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"
python3 -m $PIP_INSTALL_CMD pip
python3 -m $PIP_INSTALL_CMD setuptools
python3 -m $PIP_INSTALL_CMD neovim
