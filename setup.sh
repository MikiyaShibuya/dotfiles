# config for vim
ln -s $HOME/dotfiles/_vimrc $HOME/.vimrc

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -s $HOME/dotfiles/_init.vim $HOME/.config/nvim/init.vim

ln -s $HOME/dotfiles/_gitconfig $HOME/.gitconfig
ln -s $HOME/dotfiles/_tmux.conf $HOME/.tmux.conf
ln -s $HOME/dotfiles/zshrc $HOME/.zshrc
ln -s $HOME/dotfiles/oh-my-zsh $HOME/.oh-my-zsh
