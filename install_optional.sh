#!/bin/bash
#
# install_optional.sh - Check and interactively install dotfiles components
#
# Usage: sudo ./install_optional.sh [-r|--reinstall]
#
# Options:
#   -r, --reinstall  Show all components (including installed ones) for reinstallation
#
# This script checks installation status of all dotfiles components and
# allows you to interactively select which ones to install.
#

set -euo pipefail

# Parse command line arguments
REINSTALL_MODE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--reinstall)
            REINSTALL_MODE=1
            shift
            ;;
        -h|--help)
            echo "Usage: sudo ./install_optional.sh [-r|--reinstall]"
            echo ""
            echo "Options:"
            echo "  -r, --reinstall  Show all components for reinstallation"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "${USE_DEBUG:-}" == "1" ]]; then
    set -x
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $(id -u) -ne 0 ]]; then
    echo -e "${RED}Error: Run with sudo (e.g., sudo ./check_and_install.sh)${NC}"
    exit 1
fi

# Determine target user
if [[ -n "${SUDO_USER:-}" && ( -z "${USER:-}" || "${USER:-}" == "root" ) ]]; then
    USER="$SUDO_USER"
fi

if [[ -z "${USER:-}" || "$USER" == "root" ]]; then
    echo -e "${RED}Error: Could not determine target user. Run with sudo or set USER environment variable.${NC}"
    exit 1
fi

USER_HOME=$(eval echo ~"$USER")

# Determine OS
if [[ "$(uname)" = Darwin ]]; then
    OS='Mac'
elif [[ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]]; then
    OS='Linux'
    . /etc/os-release
    DISTRO=$ID
else
    echo -e "${RED}Error: Unsupported OS: $(uname)${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Dotfiles Component Status Checker${NC}"
echo -e "${BLUE}OS: $OS${NC}"
[[ -n "${DISTRO:-}" ]] && echo -e "${BLUE}DISTRO: $DISTRO${NC}"
echo -e "${BLUE}User: $USER${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Define components and their check functions
declare -A COMPONENT_STATUS
declare -A COMPONENT_DESC
declare -a COMPONENT_ORDER

# Helper function to check command exists
check_cmd() {
    command -v "$1" &> /dev/null
}

# Helper function to check file/dir exists
check_path() {
    [[ -e "$1" ]]
}

# Helper function to check symlink exists
check_link() {
    [[ -L "$1" ]]
}

# Define components
add_component() {
    local name="$1"
    local desc="$2"
    COMPONENT_ORDER+=("$name")
    COMPONENT_DESC["$name"]="$desc"
}

# Core components
add_component "base_packages" "Base packages (git, curl, tmux, zsh, htop, etc.)"
add_component "ripgrep" "ripgrep (fast search tool)"
add_component "neovim" "Neovim editor"
add_component "fnm_node" "fnm + Node.js"
add_component "pyenv" "pyenv (Python version manager)"
add_component "tpm" "tmux plugin manager"

# Config components
add_component "nvim_config" "Neovim configuration (symlink)"
add_component "tmux_config" "tmux configuration (symlink)"
add_component "wezterm_config" "WezTerm configuration (symlink)"
add_component "claude_config" "Claude Code configuration (symlink)"
add_component "zshrc_config" "Zsh configuration (source in .zshrc)"
add_component "gitconfig" "Git configuration"
add_component "diff_highlight" "diff-highlight for git"

# Linux-specific components
if [[ "$OS" == "Linux" && "${DISTRO:-}" == "ubuntu" ]]; then
    add_component "keyd" "keyd (keyboard remapping)"
    add_component "fusuma" "fusuma (touchpad gestures)"
    add_component "backlight_control" "Backlight control (resume fix)"
    add_component "gnome_settings" "GNOME settings (keyboard repeat, keybindings)"
    add_component "fontconfig" "Fonts + Fontconfig (Noto CJK, MesloLGS Nerd Font)"
fi

# Check status of each component
check_base_packages() {
    check_cmd git && check_cmd curl && check_cmd tmux && check_cmd zsh
}

check_ripgrep() {
    check_cmd rg
}

check_neovim() {
    check_cmd nvim
}

check_fnm_node() {
    check_path "$USER_HOME/.local/share/fnm" && check_cmd node
}

check_pyenv() {
    check_path "$USER_HOME/.pyenv"
}

check_tpm() {
    check_path "$USER_HOME/.tmux/plugins/tpm"
}

check_nvim_config() {
    check_link "$USER_HOME/.config/nvim/init.lua"
}

check_tmux_config() {
    check_link "$USER_HOME/.config/tmux/tmux.conf"
}

check_wezterm_config() {
    check_link "$USER_HOME/.config/wezterm/wezterm.lua"
}

check_claude_config() {
    check_link "$USER_HOME/.claude/settings.json"
}

check_zshrc_config() {
    grep -q "source.*dotfiles/shell/zshrc" "$USER_HOME/.zshrc" 2>/dev/null
}

check_gitconfig() {
    grep -q "Custom preference" "$USER_HOME/.gitconfig" 2>/dev/null
}

check_diff_highlight() {
    check_cmd diff-highlight || check_path /usr/share/doc/git/contrib/diff-highlight/diff-highlight
}

check_keyd() {
    check_cmd keyd && systemctl is-active --quiet keyd 2>/dev/null
}

check_fusuma() {
    check_cmd fusuma
}

check_backlight_control() {
    check_path /usr/local/bin/monitor-unlock.sh
}

check_gnome_settings() {
    # Check if GNOME settings are applied (run as target user)
    local USER_ID DBUS_ADDR
    USER_ID=$(id -u "$USER")
    DBUS_ADDR="unix:path=/run/user/${USER_ID}/bus"

    local repeat_interval delay switch_windows switch_monitor touchpad_speed
    repeat_interval=$(su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings get org.gnome.desktop.peripherals.keyboard repeat-interval" 2>/dev/null || echo "")
    delay=$(su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings get org.gnome.desktop.peripherals.keyboard delay" 2>/dev/null || echo "")
    switch_windows=$(su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings get org.gnome.desktop.wm.keybindings switch-windows" 2>/dev/null || echo "")
    switch_monitor=$(su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings get org.gnome.mutter.keybindings switch-monitor" 2>/dev/null || echo "")
    touchpad_speed=$(su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings get org.gnome.desktop.peripherals.touchpad speed" 2>/dev/null || echo "")
    [[ "$repeat_interval" == "10" || "$repeat_interval" == "uint32 10" ]] && \
    [[ "$delay" == "200" || "$delay" == "uint32 200" ]] && \
    [[ "$switch_windows" == "['<Ctrl>Tab']" ]] && \
    [[ "$switch_monitor" == "@as []" || "$switch_monitor" == "[]" ]] && \
    [[ "$touchpad_speed" == "0.5" ]]
}

check_fontconfig() {
    check_link "$USER_HOME/.config/fontconfig/fonts.conf" && \
    check_path "$USER_HOME/.local/share/fonts/MesloLGSNerdFontPropo-Regular.ttf" && \
    [[ $(fc-list 2>/dev/null) == *"Noto Sans CJK JP"* ]]
}

# Check all components
echo -e "${YELLOW}Checking component status...${NC}"
echo ""

for comp in "${COMPONENT_ORDER[@]}"; do
    if "check_$comp" 2>/dev/null; then
        COMPONENT_STATUS["$comp"]="installed"
        echo -e "  ${GREEN}✓${NC} ${COMPONENT_DESC[$comp]}"
    else
        COMPONENT_STATUS["$comp"]="not_installed"
        echo -e "  ${RED}✗${NC} ${COMPONENT_DESC[$comp]}"
    fi
done

echo ""

# Build list of selectable components
SELECTABLE=()
if [[ "$REINSTALL_MODE" == "1" ]]; then
    # Reinstall mode: show all components
    for comp in "${COMPONENT_ORDER[@]}"; do
        SELECTABLE+=("$comp")
    done
    echo -e "${YELLOW}Reinstall mode: showing all ${#SELECTABLE[@]} component(s).${NC}"
else
    # Normal mode: show only not installed
    for comp in "${COMPONENT_ORDER[@]}"; do
        if [[ "${COMPONENT_STATUS[$comp]}" == "not_installed" ]]; then
            SELECTABLE+=("$comp")
        fi
    done

    if [[ ${#SELECTABLE[@]} -eq 0 ]]; then
        echo -e "${GREEN}All components are installed!${NC}"
        echo -e "${YELLOW}Use -r or --reinstall to reinstall components.${NC}"
        exit 0
    fi

    echo -e "${YELLOW}${#SELECTABLE[@]} component(s) not installed.${NC}"
fi
echo ""

# Interactive selection
echo -e "${BLUE}Select components to install:${NC}"
echo ""

declare -A SELECTED
for i in "${!SELECTABLE[@]}"; do
    comp="${SELECTABLE[$i]}"
    SELECTED["$comp"]=0  # Default: not selected
done

while true; do
    echo "  Components to install:"
    for i in "${!SELECTABLE[@]}"; do
        comp="${SELECTABLE[$i]}"
        status_mark=""
        if [[ "$REINSTALL_MODE" == "1" && "${COMPONENT_STATUS[$comp]}" == "installed" ]]; then
            status_mark=" ${GREEN}(installed)${NC}"
        fi
        if [[ "${SELECTED[$comp]}" == "1" ]]; then
            echo -e "    ${GREEN}[$((i+1))]${NC} [x] ${COMPONENT_DESC[$comp]}${status_mark}"
        else
            echo -e "    ${YELLOW}[$((i+1))]${NC} [ ] ${COMPONENT_DESC[$comp]}${status_mark}"
        fi
    done
    echo ""
    echo "  Commands: [number] toggle, [a] select all, [n] select none, [i] install, [q] quit"
    echo -n "  > "
    read -r input

    case "$input" in
        [0-9]*)
            # Handle space-separated numbers
            for num in $input; do
                if [[ "$num" =~ ^[0-9]+$ ]]; then
                    idx=$((num - 1))
                    if [[ $idx -ge 0 && $idx -lt ${#SELECTABLE[@]} ]]; then
                        comp="${SELECTABLE[$idx]}"
                        if [[ "${SELECTED[$comp]}" == "1" ]]; then
                            SELECTED["$comp"]=0
                        else
                            SELECTED["$comp"]=1
                        fi
                    fi
                fi
            done
            ;;
        a|A)
            for comp in "${SELECTABLE[@]}"; do
                SELECTED["$comp"]=1
            done
            ;;
        n|N)
            for comp in "${SELECTABLE[@]}"; do
                SELECTED["$comp"]=0
            done
            ;;
        i|I)
            break
            ;;
        q|Q)
            echo "Cancelled."
            exit 0
            ;;
    esac
    echo ""
done

# Collect selected components
TO_INSTALL=()
for comp in "${SELECTABLE[@]}"; do
    if [[ "${SELECTED[$comp]}" == "1" ]]; then
        TO_INSTALL+=("$comp")
    fi
done

if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
    echo "No components selected."
    exit 0
fi

echo ""
echo -e "${BLUE}Installing ${#TO_INSTALL[@]} component(s)...${NC}"
echo ""

# Install functions
install_base_packages() {
    echo "Installing base packages..."
    apt-get update > /dev/null
    apt-get install --no-install-recommends -y \
        git build-essential curl unzip tmux htop less zsh \
        python3-pip python3-venv iputils-ping software-properties-common \
        > /dev/null
    echo "  Done."
}

install_ripgrep() {
    echo "Installing ripgrep..."
    apt-get update > /dev/null
    apt-get install --no-install-recommends -y ripgrep > /dev/null
    echo "  Done."
}

install_neovim() {
    echo "Installing neovim..."
    ARCH=$(uname -m)
    . /etc/os-release
    MAJOR_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f 1)

    if [[ "$ARCH" == "x86_64" ]]; then
        if (( MAJOR_VERSION >= 24 )); then
            dpkg -i "$SCRIPT_DIR"/nvim/installer/neovim_v*-noble_amd64.deb
        elif (( MAJOR_VERSION >= 22 )); then
            dpkg -i "$SCRIPT_DIR"/nvim/installer/neovim_v*-jammy_amd64.deb
        elif (( MAJOR_VERSION >= 20 )); then
            dpkg -i "$SCRIPT_DIR"/nvim/installer/neovim_v*-focal_amd64.deb
        fi
    elif [[ "$ARCH" == "aarch64" ]]; then
        if (( MAJOR_VERSION >= 24 )); then
            dpkg -i "$SCRIPT_DIR"/nvim/installer/neovim_v*-noble_arm64.deb
        elif (( MAJOR_VERSION >= 22 )); then
            dpkg -i "$SCRIPT_DIR"/nvim/installer/neovim_v*-jammy_arm64.deb
        elif (( MAJOR_VERSION >= 20 )); then
            dpkg -i "$SCRIPT_DIR"/nvim/installer/neovim_v*-focal_arm64.deb
        fi
    fi
    echo "  Done."
}

install_fnm_node() {
    echo "Installing fnm and Node.js..."
    su "$USER" -c 'if [[ ! -d "$HOME/.local/share/fnm" ]]; then curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell; fi'
    su "$USER" -c 'export PATH="$HOME/.local/share/fnm:$PATH" && eval "$(fnm env)" && fnm install 22 && fnm default 22'
    echo "  Done."
}

install_pyenv() {
    echo "Installing pyenv..."
    su "$USER" -c 'if [[ ! -d "$HOME/.pyenv" ]]; then git clone -q --depth 1 https://github.com/pyenv/pyenv.git "$HOME/.pyenv"; fi'
    echo "  Done."
}

install_tpm() {
    echo "Installing tmux plugin manager..."
    su "$USER" -c 'if [[ ! -e "$HOME/.tmux" ]]; then mkdir -p "$HOME/.tmux/plugins" && git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; fi'
    echo "  Done."
}

install_nvim_config() {
    echo "Configuring nvim..."
    su "$USER" -c "mkdir -p '$USER_HOME/.config/nvim'"
    su "$USER" -c "ln -nfs '$SCRIPT_DIR/nvim/init.lua' '$USER_HOME/.config/nvim/init.lua'"
    su "$USER" -c "ln -nfs '$SCRIPT_DIR/nvim/lua' '$USER_HOME/.config/nvim/lua'"
    su "$USER" -c "nvim --headless '+Lazy! sync' +qa &> /dev/null || true"
    echo "  Done."
}

install_tmux_config() {
    echo "Configuring tmux..."
    su "$USER" -c "mkdir -p '$USER_HOME/.config/tmux'"
    su "$USER" -c "ln -nfs '$SCRIPT_DIR/tmux/tmux.conf' '$USER_HOME/.config/tmux/tmux.conf'"
    # Install tpm plugins if tpm is installed
    if [[ -d "$USER_HOME/.tmux/plugins/tpm" ]]; then
        su "$USER" -c "'$USER_HOME/.tmux/plugins/tpm/scripts/install_plugins.sh'" || true
    fi
    echo "  Done."
}

install_wezterm_config() {
    echo "Configuring wezterm..."
    su "$USER" -c "mkdir -p '$USER_HOME/.config/wezterm'"
    su "$USER" -c "ln -nfs '$SCRIPT_DIR/wezterm/wezterm.lua' '$USER_HOME/.config/wezterm/wezterm.lua'"
    echo "  Done."
}

install_claude_config() {
    echo "Configuring Claude Code..."
    su "$USER" -c "mkdir -p '$USER_HOME/.claude'"
    su "$USER" -c "ln -nfs '$SCRIPT_DIR/claude/settings.json' '$USER_HOME/.claude/settings.json'"
    su "$USER" -c "ln -nfs '$SCRIPT_DIR/claude/CLAUDE.md' '$USER_HOME/.claude/CLAUDE.md'"
    echo "  Done."
}

install_zshrc_config() {
    echo "Configuring zshrc..."
    SOURCE_LINE="source $SCRIPT_DIR/shell/zshrc"
    ZSHRC_PATH="$USER_HOME/.zshrc"

    # If .zshrc is a symlink, replace with regular file
    if [[ -h "$ZSHRC_PATH" ]]; then
        unlink "$ZSHRC_PATH"
        touch "$ZSHRC_PATH"
        chown "$USER:$USER" "$ZSHRC_PATH"
    fi

    if ! grep -qxF "$SOURCE_LINE" "$ZSHRC_PATH" 2>/dev/null; then
        echo "# ======== Include dotfiles config ========" >> "$ZSHRC_PATH"
        echo "$SOURCE_LINE" >> "$ZSHRC_PATH"
        echo "# ========" >> "$ZSHRC_PATH"
        echo "" >> "$ZSHRC_PATH"
    fi
    echo "  Done."
}

install_gitconfig() {
    echo "Configuring git..."
    if ! grep -q "Custom preference" "$USER_HOME/.gitconfig" 2>/dev/null; then
        su "$USER" -c "cat '$SCRIPT_DIR/shell/gitconfig' >> '$USER_HOME/.gitconfig'"
    fi
    echo "  Done."
}

install_diff_highlight() {
    echo "Installing diff-highlight..."
    "$SCRIPT_DIR/shell/setup_diff_highlight.sh"
    echo "  Done."
}

install_keyd() {
    echo "Installing keyd..."
    "$SCRIPT_DIR/linux/ubuntu/keyd/install.sh"
    echo "  Done."
}

install_fusuma() {
    echo "Installing fusuma..."
    "$SCRIPT_DIR/linux/ubuntu/fusuma/install.sh"
    echo "  Done."
}

install_backlight_control() {
    echo "Installing backlight control..."
    "$SCRIPT_DIR/linux/ubuntu/backlight_control/install.sh"
    echo "  Done."
}

install_gnome_settings() {
    echo "Applying GNOME settings..."
    # Get D-Bus session address for the target user
    local USER_ID
    USER_ID=$(id -u "$USER")
    local DBUS_ADDR="unix:path=/run/user/${USER_ID}/bus"

    # Keyboard repeat settings
    su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 10"
    su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.desktop.peripherals.keyboard delay 200"
    # Window switching with Ctrl+Tab
    su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.desktop.wm.keybindings switch-windows \"['<Ctrl>Tab']\""
    # Disable switch-monitor keybinding
    su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.mutter.keybindings switch-monitor '[]'"
    # Touchpad speed
    su "$USER" -c "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' gsettings set org.gnome.desktop.peripherals.touchpad speed 0.5"
    echo "  Done."
}

install_fontconfig() {
    echo "Installing fonts and configuring fontconfig..."
    # Install Noto CJK fonts
    apt-get update > /dev/null
    apt-get install --no-install-recommends -y fonts-noto-cjk > /dev/null
    # Install MesloLGS Nerd Font
    local FONT_DIR="$USER_HOME/.local/share/fonts"
    su "$USER" -c "mkdir -p '$FONT_DIR'"
    if [[ ! -f "$FONT_DIR/MesloLGSNerdFontPropo-Regular.ttf" ]]; then
        local NERD_FONT_VERSION="v3.3.0"
        local NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/Meslo.zip"
        local TMP_DIR=$(mktemp -d)
        curl -fsSL "$NERD_FONT_URL" -o "$TMP_DIR/Meslo.zip"
        unzip -q "$TMP_DIR/Meslo.zip" -d "$TMP_DIR/Meslo"
        # Copy as root and fix ownership (su cannot access root's temp dir)
        cp "$TMP_DIR"/Meslo/MesloLGSNerdFontPropo-*.ttf "$FONT_DIR/"
        chown "$USER:$USER" "$FONT_DIR"/MesloLGSNerdFontPropo-*.ttf
        rm -rf "$TMP_DIR"
    fi
    # Configure fontconfig
    su "$USER" -c "mkdir -p '$USER_HOME/.config/fontconfig'"
    su "$USER" -c "ln -nfs '$SCRIPT_DIR/linux/fontconfig/fonts.conf' '$USER_HOME/.config/fontconfig/fonts.conf'"
    # Rebuild font cache
    su "$USER" -c "fc-cache -f" 2>/dev/null || true
    echo "  Done."
}

# Execute installations
for comp in "${TO_INSTALL[@]}"; do
    echo ""
    "install_$comp"
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"

# Show post-install notes
NOTES=()
for comp in "${TO_INSTALL[@]}"; do
    case "$comp" in
        fusuma)
            NOTES+=("fusuma: Log out and back in for input group. Then: systemctl --user daemon-reload && systemctl --user enable --now fusuma")
            ;;
        zshrc_config)
            NOTES+=("zsh: Run 'chsh -s \$(which zsh)' to set zsh as default shell")
            ;;
    esac
done

if [[ ${#NOTES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Post-installation notes:${NC}"
    for note in "${NOTES[@]}"; do
        echo "  - $note"
    done
fi
