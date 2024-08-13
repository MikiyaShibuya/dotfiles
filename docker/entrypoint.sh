#!/bin/bash

# su $USER -c "mkdir -p /home/$USER/host-disk/nvim-coc"
# ln -sfn /home/$USER/host-disk/nvim-coc /home/$USER/.config/coc

su $USER -c "mkdir -p /home/$USER/host-disk/nvim-tmp"
ln -sfn /home/$USER/host-disk/nvim-tmp /home/$USER/.config/nvim/tmp

su $USER -c "touch /home/$USER/host-disk/zsh-history"
ln -sfn /home/$USER/host-disk/zsh-history /home/$USER/.zsh-history

su $USER -c "mkdir -p /home/$USER/host-disk/p10k"
ln -sfn /home/$USER/host-disk/p10k /home/shibuya/.cache/p10k

su $USER -c "mkdir -p /home/$USER/host-disk/github-copilot"
ln -sfn /home/$USER/host-disk/github-copilot /home/shibuya/.config/github-copilot

# su $USER -c "cp /home/$USER/.ssh/dotfiles_ssh /keys"
service ssh start
sleep infinity

