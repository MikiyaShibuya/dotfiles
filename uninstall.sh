#!/bin/bash
#
# uninstall.sh - Remove dotfiles symlinks and configurations
#
# Usage: ./uninstall.sh
#
# This script removes symlinks created by as_user_install.sh.
# Note: .gitconfig and .zshrc contain appended content that must be
# manually removed if desired.
#

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

# Determine OS
if [[ "$(uname)" = Darwin ]]; then
    OS='Mac'
elif [[ "$(expr substr $(uname -s) 1 5)" = Linux ]]; then
    OS='Linux'
else
    OS=''
fi

# Helper function to safely remove symlinks
remove_symlink() {
    local path="$1"
    if [[ -L "$path" ]]; then
        echo "Removing symlink: $path"
        unlink "$path"
    elif [[ -e "$path" ]]; then
        echo "Skipping (not a symlink): $path"
    fi
}

echo "Removing dotfiles symlinks..."

# Neovim
remove_symlink "$HOME/.config/nvim/init.lua"
remove_symlink "$HOME/.config/nvim/lua"

# Tmux
remove_symlink "$HOME/.config/tmux/tmux.conf"
remove_symlink "$HOME/.tmux.conf"  # Legacy location for Tmux < 3.1

# WezTerm
remove_symlink "$HOME/.config/wezterm/wezterm.lua"

# Claude Code
remove_symlink "$HOME/.claude/settings.json"
remove_symlink "$HOME/.claude/CLAUDE.md"

echo ""
echo "Symlinks removed."
echo ""
echo "NOTE: The following files contain appended dotfiles configuration"
echo "that must be manually edited if you want to remove it:"
echo "  - ~/.gitconfig (look for '# Custom preference' section)"
echo "  - ~/.zshrc (look for '# ======== Include dotfiles config ========' section)"
