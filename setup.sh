# config for vim
ln -nfs $PWD/vimrc $HOME/.vimrc

# config for nvim
mkdir -p  $HOME/.config/nvim
ln -nfs $PWD/init.vim $HOME/.config/nvim/init.vim

# git, tmux, zshrc setting
ln -nfs $PWD/gitconfig $HOME/.gitconfig
ln -nfs $PWD/tmux.conf $HOME/.tmux.conf
ln -nfs $PWD/zshrc $HOME/.zshrc
ln -nfs $PWD/p10k.zsh $HOME/.p10k.zsh

# dein & coc settings for nvim
ln -nfs $PWD/dein.toml $HOME/.config/nvim/dein.toml
ln -nfs $PWD/dein_lazy.toml $HOME/.config/nvim/dein_lazy.toml
ln -nfs $PWD/coc-settings.json $HOME/.config/nvim/coc-settings.json

