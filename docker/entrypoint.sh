#!/bin/bash

# set -e

su $USER -c "mkdir -p /home/$USER/host-disk/nvim-tmp"
ln -sfn /home/$USER/host-disk/nvim-tmp /home/$USER/.config/nvim/tmp

su $USER -c "touch /home/$USER/host-disk/zsh-history"
ln -sfn /home/$USER/host-disk/zsh-history /home/$USER/.zsh-history

su $USER -c "mkdir -p /home/$USER/host-disk/p10k"
ln -sfn /home/$USER/host-disk/p10k /home/$USER/.cache/p10k

su $USER -c "mkdir -p /home/$USER/host-disk/github-copilot"
ln -sfn /home/$USER/host-disk/github-copilot /home/$USER/.config/github-copilot


# SSH server setup
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
sed "s@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g" -i /etc/pam.d/sshd

service ssh start
echo "SSH server started on port $SSH_PORT"
sleep infinity

