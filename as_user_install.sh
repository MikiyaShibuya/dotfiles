#!/bin/bash
#
# as_user_install.sh - User-level setup for dotfiles
#
# Usage: Called from install.sh (do not run directly)
#
# Environment variables:
#   DOTFILES_DIR  Path to dotfiles directory (required, set by install.sh)
#   USE_DEBUG=1   Enable debug output (set -x)
#

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

if [[ "${USE_DEBUG:-}" == "1" ]]; then
    set -x
fi

if [[ $(id -u) == 0 ]]; then
    echo "Error: Run as NON-ROOT user"
    exit 1
fi

if [[ "${USER:-}" == root ]]; then
    echo "Error: Run as NON-ROOT user"
    exit 1
fi

# Use DOTFILES_DIR if set, otherwise derive from script location
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
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
grep -q "Custom preference" "$HOME/.gitconfig" &> /dev/null || \
  cat "$DOTFILES_DIR/shell/gitconfig" >> "$HOME/.gitconfig"

# Configure nvim
mkdir -p "$HOME/.config/nvim"
ln -nfs "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
ln -nfs "$DOTFILES_DIR/nvim/lua" "$HOME/.config/nvim/lua"
nvim --headless "+Lazy! sync" +qa &> /dev/null || true


# ==== ZSH Setting ====

# If .zshrc is a symlink, replace with regular file
if [[ -h "$HOME/.zshrc" ]]; then
  unlink "$HOME/.zshrc"
  touch "$HOME/.zshrc"
fi

SOURCE_LINE="source $DOTFILES_DIR/shell/zshrc"
ZSHRC_PATH="$HOME/.zshrc"
if ! grep -qxF "$SOURCE_LINE" "$ZSHRC_PATH"; then
  echo "# ======== Include dotfiles config ========" >> "$ZSHRC_PATH"
  echo "$SOURCE_LINE" >> "$ZSHRC_PATH"
  echo "# ========" >> "$ZSHRC_PATH"
  echo "" >> "$ZSHRC_PATH"
fi


# ==== TMUX Setting ====
mkdir -p "$HOME/.config/tmux"
ln -nfs "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# ==== WezTerm Setting ====
mkdir -p "$HOME/.config/wezterm"
ln -nfs "$DOTFILES_DIR/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

# ==== Claude Code Setting ====
mkdir -p "$HOME/.claude"
ln -nfs "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
ln -nfs "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Install tpm (tmux plugin manager)
if [[ ! -e "$HOME/.tmux" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi


# ==== pyenv ====
if [[ ! -d "$HOME/.pyenv" ]]; then
    git clone -q --depth 1 https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
fi

if [[ $OS = Mac ]]; then
    defaults write -g InitialKeyRepeat -int 11 # 15ms x 11 = 165ms
    defaults write -g KeyRepeat -int 1 # 15ms x 1 = 15ms
fi

# Install Python packages for neovim
export PIP_BREAK_SYSTEM_PACKAGES=1
PIP_TRUSTED_HOSTS="--trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"
python3 -m pip install $PIP_TRUSTED_HOSTS pip
python3 -m pip install $PIP_TRUSTED_HOSTS setuptools
python3 -m pip install $PIP_TRUSTED_HOSTS neovim
