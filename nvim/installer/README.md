# Neovim Installer

## Updating deb packages

```bash
cd nvim/installer
./build_debs.sh
```

Interactive prompts:
1. Fetches and displays latest neovim version from GitHub
2. Asks for confirmation to continue
3. Shows build target selection menu:
   ```
   Select build targets (space-separated numbers, or 'all'):

     1) focal amd64
     2) focal arm64
     3) jammy amd64
     4) jammy arm64
     5) noble amd64
     6) noble arm64

   Selection: 3 4
   ```

Requirements:
- Docker
- For cross-arch builds: `sudo apt-get install -y qemu-user-static binfmt-support`

Note: Cross-architecture builds via QEMU are slow (30min+). Run on native architecture when possible.

## Manual build (legacy)

```bash
git clone https://github.com/neovim/neovim.git
cd neovim
git checkout v0.11.2
make CMAKE_BUILD_TYPE=Release
cd build
cpack -G DEB
```
