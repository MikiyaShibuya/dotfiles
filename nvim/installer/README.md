# Neovim Installer

## Build deb package

clone neovim repository
```bash
git clone https://github.com/neovim/neovim.git
cd neovim
```
# build neovim
```bash
make CMAKE_BUILD_TYPE=Release
```
# create deb package
```bash
sudo checkinstall
# If "/usr/local/.../man is not a directory" error occurs, run: sudo make install before checkinstall
```


