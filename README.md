dotfiles
==

Personal dotfiles for macOS and Ubuntu Linux.

## What's Included

| Category | Tools |
|----------|-------|
| Shell | Zsh, Powerlevel10k, fzf, zsh-autosuggestions |
| Editor | Neovim (NvChad), LSP, Copilot |
| Terminal | Tmux (catppuccin theme) |
| Node.js | fnm (Fast Node Manager) |
| Python | pyenv |
| Ubuntu | keyd (keyboard remapping), fusuma (gestures) |
| macOS | Karabiner-Elements, iTerm2 |

## Installation

Run one-liner to setup dotfiles.
This repo will be cloned to `~/.local/share/dotfiles`.
```bash
curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/main/setup_dotfiles.sh | bash -s --
```
(Optional) Change default shell to zsh.
```bash
sudo chsh $USER -s /bin/zsh
```

## Supported Platforms

- Ubuntu 20.04 (focal), 22.04 (jammy), 24.04 (noble)
- macOS (Intel / Apple Silicon)

## Test in Container

```bash
cd docker
U=`id -u` G=`id -g` docker compose up --build
```
To use other Ubuntu versions:
```bash
cd docker
U=`id -u` G=`id -g` UBUNTU_CODENAME=jammy docker compose up --build
```

## Directory Structure

```
.
├── shell/          # Zsh, git config, powerlevel10k
├── nvim/           # Neovim configuration (NvChad)
├── tmux/           # Tmux configuration
├── linux/
│   └── ubuntu/     # Ubuntu-specific (keyd, fusuma)
├── macos/
│   ├── karabiner/  # Keyboard remapping
│   └── iterm2/     # iTerm2 profile
├── docker/         # Dockerfile, compose.yaml
├── install.sh      # Main installer (run as root)
└── as_user_install.sh  # User-level setup
```

## Setup SSH-Agent sudo auth

Execute sudo commands without password by authenticating with SSH key.
Add your pubkey to `~/.ssh/authorized_keys` and run:
```bash
curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/main/shell/setup_ssh_agent_auth.sh | sudo bash -s -- ~/.ssh/authorized_keys
```
