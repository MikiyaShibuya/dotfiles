dotfiles
==

## Installation
Run one-liner to setup dotfiles.  
This repo will be cloned to `~/.local/share/dotfiles`.  
```bash
curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/main/setup_dotfiles.sh | bash -s --
```
(Opional) Change to zsh.  
```bash
sudo chsh $USER -s /bin/zsh  
```
That's all.

## Test in container
```bash
U=`id -u` G=`id -g` docker compose up --build
```
To use other than Ubuntu noble
```bash
U=`id -u` G=`id -g` UBUNTU_CODENAME=jammy docker compose up --build
```

## Setup SSH-Agent sudo auth
You can execute sudo command with no password required by authenticating with ssh key.  
Add your pubkey to `~/.ssh/authorized_keys` and run the following command to enable this feature.  
```bash
curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/main/shell/setup_ssh_agent_auth.sh  | sudo bash -s -- ~/.ssh/authorized_keys
```
