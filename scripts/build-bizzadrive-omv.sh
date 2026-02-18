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
        cd "$pkgdir"

        echo "[*] Installing build-deps for $pkgdir"
        apt build-dep -y . || true

        echo "[*] Building $pkgdir"
        dpkg-buildpackage -us -uc -b

        cd "$OMV_DEB_DIR"
    fi
done

echo "[*] Publishing packages..."

cd "$OMV_DEB_DIR"

for pkg in *.deb; do
    if [ -f "$pkg" ]; then
        echo "  → Including $pkg"
        reprepro -b "$REPO_DIR" includedeb "$DIST" "$pkg"
    fi
done

echo "[*] Done."