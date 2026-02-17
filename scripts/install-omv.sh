#!/bin/sh

set -eu

REPO_URL="https://github.com/dragenox/openmediavault.git"
SRC_DIR="/usr/src/openmediavault"

echo "[*] BizzaDrive OMV Installer"
echo "[*] Checking root..."

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Must run as root"
    exit 1
fi

echo "[*] Updating system..."
apt update

echo "[*] Installing build dependencies..."
apt install -y git build-essential devscripts \
    dpkg-dev debhelper fakeroot lintian equivs

if [ ! -d "$SRC_DIR" ]; then
    echo "[*] Cloning OMV fork..."
    git clone "$REPO_URL" "$SRC_DIR"
else
    echo "[*] OMV source already exists, pulling latest..."
    cd "$SRC_DIR"
    git pull
fi

cd "$SRC_DIR/deb"

echo "[*] Installing build dependencies from control file..."
apt build-dep -y .

echo "[*] Building packages..."
dpkg-buildpackage -us -uc -b

echo "[*] Installing built packages..."
cd ..
dpkg -i openmediavault*.deb || apt -f install -y

echo "[*] Rebuilding OMV workbench..."
omv-mkworkbench all

echo "[*] Done. Reboot recommended."