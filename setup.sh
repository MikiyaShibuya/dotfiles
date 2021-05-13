# config for vim
ln -nfs $PWD/vimrc $HOME/.vimrc

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -nfs $PWD/init.vim $HOME/.config/nvim/init.vim

ln -nfs $PWD/gitconfig $HOME/.gitconfig
ln -nfs $PWD/tmux.conf $HOME/.tmux.conf
