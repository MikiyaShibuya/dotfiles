# config for vim
ln -s $PWD/vimrc $HOME/.vimrc

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -s $PWD/init.vim $HOME/.config/nvim/init.vim

ln -s $PWD/gitconfig $HOME/.gitconfig
ln -s $PWD/tmux.conf $HOME/.tmux.conf
