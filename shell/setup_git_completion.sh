#!/bin/bash


# Description
echo "" >> ~/.bashrc
echo "#git completion and prompt" >> ~/.bashrc

# Download git-completion
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O ~/.git-completion.bash
chmod a+x ~/.git-completion.bash
echo "source ~/.git-completion.bash" >> ~/.bashrc

# Download git-prompt
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O ~/.git-prompt.sh
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O ~/.git-prompt.sh
echo "source ~/.git-prompt.sh" >> ~/.bashrc

# Change prompt
echo 'PS1="\[\033[1;32m\]\$(date +%Y/%m/%d_%H:%M:%S)\[\033[0m\] \[\033[33m\]\H:\w\n\[\033[0m\][\u@ \W]\[\033[36m\]\$(__git_ps1)\[\033[00m\]\$ "' >> ~/.bashrc
echo 'GIT_PS1_SHOWDIRTYSTATE=1' >> ~/.bashrc

# Apply these changes
source ~/.bashrc

