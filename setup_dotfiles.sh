#!/bin/bash

# curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/master/setup_dotfiles.sh | sudo bash -s --

set -e

export USER=$USER
export HOMEDIR=$(echo ~$USER)
REPO_URL=https://github.com/MikiyaShibuya/dotfiles.git

mkdir -p $HOMEDIR/.local/share
cd $HOMEDIR/.local/share

git clone $REPO_URL --depth=1
cd dotfiles

sudo USER=$USER ./install.sh
