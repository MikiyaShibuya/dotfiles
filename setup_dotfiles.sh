#!/bin/bash

# curl -fsL https://raw.githubusercontent.com/MikiyaShibuya/dotfiles/refs/heads/master/setup_dotfiles.sh | bash -s --

set -e

export USER=$(whoami)
export HOMEDIR=$(eval echo ~$USER)
REPO_URL=https://github.com/MikiyaShibuya/dotfiles.git

mkdir -p $HOMEDIR/.local/share
cd $HOMEDIR/.local/share

if [ -d dotfiles ]; then
  echo "Uninstalling previous installed dotfiles"
  cd dotfiles
  if [ -f uninstall.sh ]; then
    ./uninstall.sh | true
  fi
  cd ..
  rm -r dotfiles
fi

git clone $REPO_URL --depth=1
cd dotfiles

sudo USER=$USER ./install.sh
