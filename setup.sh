# config for vim
ln -s $HOME/dotfiles/_vimrc $HOME/.vimrc

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -s $HOME/dotfiles/_init.vim $HOME/.config/nvim/init.vim

ln -s $HOME/dotfiles/_gitconfig $HOME/.gitconfig
ln -s $HOME/dotfiles/tmux.conf $HOME/.tmux.conf
ln -s $HOME/dotfiles/zshrc $HOME/.zshrc
ln -s $HOME/dotfiles/p10k.zsh $HOME/.p10k.zsh

ln -s $HOME/dotfiles/dein.toml $HOME/.config/nvim/dein.toml
ln -s $HOME/dotfiles/dein_lazy.toml $HOME/.config/nvim/dein_lazy.toml
ln -s $HOME/dotfiles/coc_settings.json $HOME/.config/nvim/coc_settings
