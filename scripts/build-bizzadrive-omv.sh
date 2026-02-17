#!/bin/sh

set -eu

# --- CONFIG ---
BASE_DIR="/usr/src/bizzadrive"
OMV_DIR="$BASE_DIR/openmediavault"
PKG_DIR="$OMV_DIR/deb/openmediavault"
REPO_DIR="/srv/bizzadrive-repo"
DIST="trixie"

echo "[*] BizzaDrive OMV Build Script"
echo "[*] Running as: $(whoami)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Must run as root"
    exit 1
fi

echo "[*] Updating OMV source..."
cd "$OMV_DIR"
git pull --ff-only

echo "[*] Cleaning previous builds..."
cd "$PKG_DIR"
dpkg-buildpackage -T clean || true

echo "[*] Building package..."
dpkg-buildpackage -us -uc -b

echo "[*] Locating built package..."
cd "$OMV_DIR/deb"
PKG_FILE=$(ls bizzadrive-omv_*_all.deb | sort | tail -n 1)

if [ ! -f "$PKG_FILE" ]; then
    echo "Error: Built package not found."
    exit 1
fi

echo "[*] Adding package to repository..."
reprepro -b "$REPO_DIR" includedeb "$DIST" "$PKG_FILE"

echo "[*] Repository updated successfully."

echo "[*] Done."