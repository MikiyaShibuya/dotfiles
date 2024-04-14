#!/bin/bash

su $USER -c "touch /home/$USER/host-disk/zsh-history"
ln -sfn /home/$USER/host-disk/zsh-history /home/$USER/.zsh-history

su $USER -c "cp /home/$USER/.ssh/dotfiles_ssh /keys"
service ssh start
sleep infinity

