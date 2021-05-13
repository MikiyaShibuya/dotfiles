# config for vim
ln -nfs $PWD/vimrc $HOME/.vimrc

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -nfs $PWD/init.vim $HOME/.config/nvim/init.vim

ln -nfs $PWD/gitconfig $HOME/.gitconfig
ln -nfs $PWD/tmux.conf $HOME/.tmux.conf
ln -s $PWD/zshrc $HOME/.zshrc
ln -s $PWD/p10k.zsh $HOME/.p10k.zsh

ln -s $PWD/dein.toml $HOME/.config/nvim/dein.toml
ln -s $PWD/dein_lazy.toml $HOME/.config/nvim/dein_lazy.toml
ln -s $PWD/coc-settings.json $HOME/.config/nvim/coc-settings.json

