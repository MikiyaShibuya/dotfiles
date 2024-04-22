
# Determine OS
if [ "$(uname)" = 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
else
    OS=''
fi

unlink $HOME/.gitconfig
unlink $HOME/.tmux.conf
unlink $HOME/.zshrc

if [ $OS = 'Mac' ]; then
    unlink $HOME/.p10k.zsh
elif [ $OS = 'Linux' ]; then
    unlink $HOME/.p10k.zsh
fi

unlink $HOME/.config/nvim/init.vim
unlink $HOME/.config/nvim/dein.toml
unlink $HOME/.config/nvim/dein_lazy.toml
unlink $HOME/.config/nvim/coc-settings.json
unlink $HOME/.config/nvim/coc-hook-add.vim
