#!/bin/bash
# VSCode extensions to replicate Neovim/NvChad environment
# Run on the HOST machine where VSCode is installed

set -e

extensions=(
  # === Core: Neovim backend (replaces VSCodeVim) ===
  asvetliakov.vscode-neovim              # Real Neovim as backend (fast_cursor etc.)

  # === Theme: onedark ===
  zhuangtongfa.Material-theme            # One Dark Pro theme
  PKief.material-icon-theme              # Material file icons (nvim-web-devicons)

  # === Git: gitsigns equivalent ===
  eamodio.gitlens                        # Git blame, history, hunk navigation

  # === AI ===
  anthropic.claude-code                  # Claude Code IDE integration (diff view, selection context)

  # === Languages: mason.nvim equivalents ===
  ms-python.python                       # Python support
  ms-python.vscode-pylance               # Pylance (basedpyright equivalent)
  llvm-vs-code-extensions.vscode-clangd  # clangd (C/C++)

  # === Markdown: markdown-preview.nvim equivalent ===
  yzhang.markdown-all-in-one             # Markdown editing support
  shd101wyy.markdown-preview-enhanced    # Live preview (mkdp equivalent)

  # === Remote Development (for container access) ===
  ms-vscode-remote.remote-containers     # Dev Containers
  ms-vscode-remote.remote-ssh            # Remote SSH
)

# vscode-neovim と normal mode を奪い合うため、同居させない
conflicting=(
  vscodevim.vim
)

echo "Installing VSCode extensions..."
for ext in "${extensions[@]}"; do
  [[ "$ext" =~ ^# ]] && continue
  echo "  Installing: $ext"
  code --install-extension "$ext" --force 2>/dev/null || \
    echo "    WARNING: Failed to install $ext"
done

echo "Removing conflicting extensions..."
installed="$(code --list-extensions 2>/dev/null)"
for ext in "${conflicting[@]}"; do
  if grep -qix "$ext" <<<"$installed"; then
    echo "  Uninstalling: $ext"
    code --uninstall-extension "$ext" 2>/dev/null || \
      echo "    WARNING: Failed to uninstall $ext"
  fi
done

echo ""
echo "Done!"
echo ""
echo "=== Setup instructions ==="
echo ""
echo "1. Copy config files to VSCode user directory:"
echo "   DOTFILES=~/.local/share/dotfiles/vscode"
echo ""
echo "   # Linux"
echo "   cp \$DOTFILES/settings.json ~/.config/Code/User/settings.json"
echo "   cp \$DOTFILES/keybindings.json ~/.config/Code/User/keybindings.json"
echo ""
echo "2. Neovim init for vscode-neovim is loaded automatically from:"
echo "   ~/.local/share/dotfiles/vscode/vscode-neovim-init.lua"
echo "   (configured in settings.json via vscode-neovim.neovimInitVimPaths.linux)"
echo ""
echo "3. Ensure Neovim is installed on the host (required by vscode-neovim):"
echo "   nvim --version"
echo ""
echo "4. Restart VSCode"
