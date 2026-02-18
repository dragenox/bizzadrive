#!/bin/sh
set -eu

BASE_DIR="/usr/src/bizzadrive"
OMV_DEB_DIR="$BASE_DIR/openmediavault/deb"
REPO_DIR="/srv/bizzadrive-repo"
DIST="trixie"

echo "[*] BizzaDrive Full OMV Build"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root."
    exit 1
fi

cd "$OMV_DEB_DIR"

for pkgdir in */; do
    if [ -f "$pkgdir/debian/control" ]; then
        echo "[*] Building $pkgdir"
        cd "$pkgdir"
        dpkg-buildpackage -us -uc -b
        cd "$OMV_DEB_DIR"
    fi
done

echo "[*] Publishing packages..."

find "$OMV_DEB_DIR" -name "*.deb" -type f | while read -r deb; do
    echo "  → Including $deb"
    reprepro -b "$REPO_DIR" includedeb "$DIST" "$deb"
done

echo "[*] Done."