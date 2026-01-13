#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR"

# Check if docker is available
if ! command -v docker &>/dev/null; then
    echo "Error: docker is required but not installed"
    exit 1
fi

# Fetch latest neovim release version from GitHub
fetch_latest_version() {
    local version
    version=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [[ -z "$version" ]]; then
        echo "Error: Failed to fetch latest version from GitHub" >&2
        exit 1
    fi
    echo "$version"
}

# Build deb package in docker container
build_deb() {
    local distro_name="$1"
    local arch="$2"
    local version="$3"
    local platform=""
    local deb_arch=""

    case "$arch" in
        amd64)
            platform="linux/amd64"
            deb_arch="amd64"
            ;;
        arm64)
            platform="linux/arm64"
            deb_arch="arm64"
            ;;
        *)
            echo "Error: Unsupported architecture: $arch"
            return 1
            ;;
    esac

    local output_name="neovim_v${version}-1-${distro_name}_${deb_arch}.deb"
    local image="ubuntu:${distro_name}"

    echo "========================================"
    echo "Building: $output_name"
    echo "Platform: $platform"
    echo "========================================"

    docker run --rm --platform "$platform" \
        -v "$OUTPUT_DIR:/output" \
        -e VERSION="$version" \
        -e DEB_ARCH="$deb_arch" \
        -e DISTRO_NAME="$distro_name" \
        -e HOST_UID="$(id -u)" \
        -e HOST_GID="$(id -g)" \
        "$image" bash -c '
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC

echo "Installing build dependencies..."
apt-get update
apt-get install -y \
    git cmake ninja-build gettext curl unzip \
    build-essential libtool-bin autoconf automake pkg-config

echo "Cloning neovim v$VERSION..."
git clone --depth 1 --branch "v$VERSION" https://github.com/neovim/neovim.git /tmp/neovim
cd /tmp/neovim

echo "Building neovim..."
make CMAKE_BUILD_TYPE=Release

echo "Creating deb package..."
cd build
cpack -G DEB

# Find and copy the generated deb file
DEB_FILE=$(ls -1 nvim-linux*.deb 2>/dev/null | head -1)
if [[ -z "$DEB_FILE" ]]; then
    echo "Error: No deb file generated"
    exit 1
fi

OUTPUT_NAME="neovim_v${VERSION}-1-${DISTRO_NAME}_${DEB_ARCH}.deb"
cp "$DEB_FILE" "/output/$OUTPUT_NAME"
chown "${HOST_UID}:${HOST_GID}" "/output/$OUTPUT_NAME"
echo "Created: $OUTPUT_NAME"
'

    if [[ -f "$OUTPUT_DIR/$output_name" ]]; then
        echo "Successfully created: $output_name"
        # Remove old versions for this distro/arch after successful build
        local old_files
        old_files=$(ls -1 "$OUTPUT_DIR"/neovim_v*-${distro_name}_${deb_arch}.deb 2>/dev/null | grep -v "$output_name" || true)
        if [[ -n "$old_files" ]]; then
            echo "Removing old versions:"
            echo "$old_files" | while read -r f; do
                echo "  - $(basename "$f")"
                rm -f "$f"
            done
        fi
    else
        echo "Error: Failed to create $output_name"
        return 1
    fi
}

# Main
echo "Fetching latest neovim version..."
VERSION=$(fetch_latest_version)
echo ""
echo "Latest version: v$VERSION"
echo ""
read -p "Continue with this version? [Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Detect current environment
detect_current_env() {
    local arch=""
    local distro=""

    case "$(uname -m)" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
    esac

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$VERSION_CODENAME" in
            focal|jammy|noble) distro="$VERSION_CODENAME" ;;
        esac
    fi

    if [[ -n "$arch" && -n "$distro" ]]; then
        echo "$distro $arch"
    fi
}

CURRENT_ENV=$(detect_current_env)
CURRENT_ARCH=$(echo "$CURRENT_ENV" | awk '{print $2}')

# Define all available targets, sorted by current arch first
if [[ "$CURRENT_ARCH" == "arm64" ]]; then
    ALL_TARGETS=(
        "focal arm64"
        "jammy arm64"
        "noble arm64"
        "focal amd64"
        "jammy amd64"
        "noble amd64"
    )
else
    ALL_TARGETS=(
        "focal amd64"
        "jammy amd64"
        "noble amd64"
        "focal arm64"
        "jammy arm64"
        "noble arm64"
    )
fi

echo ""
echo "Select build targets (space-separated numbers, or 'all'):"
echo ""
for i in "${!ALL_TARGETS[@]}"; do
    marker=""
    if [[ "${ALL_TARGETS[$i]}" == "$CURRENT_ENV" ]]; then
        marker=" (current)"
    fi
    echo "  $((i+1))) ${ALL_TARGETS[$i]}$marker"
done
echo ""
read -p "Selection: " -r SELECTION

TARGETS=()
if [[ "$SELECTION" == "all" ]]; then
    TARGETS=("${ALL_TARGETS[@]}")
else
    for num in $SELECTION; do
        idx=$((num-1))
        if [[ $idx -ge 0 && $idx -lt ${#ALL_TARGETS[@]} ]]; then
            TARGETS+=("${ALL_TARGETS[$idx]}")
        else
            echo "Warning: Invalid selection $num, skipping"
        fi
    done
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo "No targets selected. Aborted."
    exit 0
fi

# Check for existing debs with same version
EXISTING=()
for target in "${TARGETS[@]}"; do
    read -r distro arch <<< "$target"
    deb_file="$OUTPUT_DIR/neovim_v${VERSION}-1-${distro}_${arch}.deb"
    if [[ -f "$deb_file" ]]; then
        EXISTING+=("$target")
    fi
done

SKIP_TARGETS=()
if [[ ${#EXISTING[@]} -gt 0 ]]; then
    echo ""
    echo "The following targets already have v$VERSION debs:"
    for t in "${EXISTING[@]}"; do
        echo "  - $t"
    done
    echo ""
    read -p "Rebuild these? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_TARGETS=("${EXISTING[@]}")
    fi
fi

# Remove old versions (different from target version) for all selected targets
for target in "${TARGETS[@]}"; do
    read -r distro arch <<< "$target"
    current_deb="neovim_v${VERSION}-1-${distro}_${arch}.deb"
    old_files=$(ls -1 "$OUTPUT_DIR"/neovim_v*-${distro}_${arch}.deb 2>/dev/null | grep -v "$current_deb" || true)
    if [[ -n "$old_files" ]]; then
        echo "Removing old versions for $distro $arch:"
        echo "$old_files" | while read -r f; do
            echo "  - $(basename "$f")"
            rm -f "$f"
        done
    fi
done

echo ""
echo "Building targets:"
for t in "${TARGETS[@]}"; do
    skip=""
    for s in "${SKIP_TARGETS[@]}"; do
        if [[ "$t" == "$s" ]]; then
            skip=" (skipped - existing)"
        fi
    done
    echo "  - $t$skip"
done
echo ""

FAILED=()

for target in "${TARGETS[@]}"; do
    # Check if target should be skipped
    skip=false
    for s in "${SKIP_TARGETS[@]}"; do
        if [[ "$target" == "$s" ]]; then
            skip=true
            break
        fi
    done
    if $skip; then
        continue
    fi

    read -r distro arch <<< "$target"
    if ! build_deb "$distro" "$arch" "$VERSION"; then
        FAILED+=("${distro}_${arch}")
    fi
    echo ""
done

echo "========================================"
echo "Build Summary"
echo "========================================"
echo "Version: $VERSION"
echo ""

if [[ ${#FAILED[@]} -eq 0 ]]; then
    echo "All builds succeeded!"
else
    echo "Failed builds:"
    for f in "${FAILED[@]}"; do
        echo "  - $f"
    done
    exit 1
fi

echo ""
echo "Generated files:"
ls -la "$OUTPUT_DIR"/neovim_v${VERSION}*.deb 2>/dev/null || echo "No files found"
