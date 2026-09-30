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

### Manual Installation

If you prefer to clone the repository manually:
```bash
git clone https://github.com/MikiyaShibuya/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
sudo ./install.sh
```

(Optional) Change default shell to zsh.
```bash
sudo chsh $USER -s /bin/zsh
```

### Optional Components

Interactively install optional components (keyd, fusuma, ripgrep, etc.):
```bash
sudo ./install_optional.sh
```

To reinstall existing components:
```bash
sudo ./install_optional.sh -r
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
├── private/        # Work-internal config (private submodule, optional)
├── install.sh      # Main installer (run as root)
├── install_optional.sh  # Interactive optional component installer
└── as_user_install.sh  # User-level setup
```

## Private Configuration

This repository is public, so it must not contain work-internal hostnames, machine
names, repository names, container names, or internal branch names. Such settings
live in a separate private repository mounted at `private/` as a submodule.

`as_user_install.sh` symlinks the private files into place only when the submodule
is checked out, so a clone without access to it still installs and runs with the
public configuration alone.

| Private file | Consumer |
| --- | --- |
| `private/claude/CLAUDE.private.md` | imported by `claude/CLAUDE.md` |
| `private/claude/settings.local.json` | merged into `claude/settings.json` by Claude Code |
| `private/nvim/dap_projects.lua` | loaded by `nvim/lua/custom/configs/dap.lua` if present |

To check it out:

```bash
git submodule update --init --recursive
./as_user_install.sh
```

## Claude Code transcript の退避

Claude Code は `cleanupPeriodDays`（`claude/settings.json` で 90 日）を過ぎた
`~/.claude/projects/**/*.jsonl` を削除する。削除タイミングに依存せず残すため、
user systemd timer `claude-transcript-archive.timer` が毎日全 transcript を
`~/.claude-archive/projects/` へ zstd 圧縮で複製する（`as_user_install.sh` が登録）。

- 退避版は削除しない。圧縮後の増加は約 100MB/月
- 元より新しい退避版はスキップし、追記されたセッションだけ再圧縮する
- root 所有で読めないディレクトリ（コンテナ内の Claude が作るもの）は対象外

```bash
# 検索（圧縮のまま）
rg -z '<keyword>' ~/.claude-archive/projects/
# 手動実行・結果確認
systemctl --user start claude-transcript-archive.service
journalctl --user -u claude-transcript-archive.service -n 5
# 削除済みセッションを resume できる状態に戻す
zstd -d ~/.claude-archive/projects/<slug>/<uuid>.jsonl.zst -o ~/.claude/projects/<slug>/<uuid>.jsonl
```

## Setup SSH-Agent sudo auth

Execute sudo commands without password by authenticating with SSH key.
Add your pubkey to `~/.ssh/authorized_keys` and run:
```bash
curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/main/shell/setup_ssh_agent_auth.sh | sudo bash -s -- ~/.ssh/authorized_keys
```
