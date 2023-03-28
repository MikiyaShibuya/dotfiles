#!/bin/bash
su $USER -c "cp /home/$USER/.ssh/dotfiles_ssh /keys"
service ssh start
# su $USER -c "nvim -qa"
su $USER -c read

