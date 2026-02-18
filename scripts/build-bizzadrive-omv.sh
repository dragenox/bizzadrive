#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_BASE_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

BASE_DIR="${BASE_DIR:-$DEFAULT_BASE_DIR}"
OMV_DEB_DIR="${OMV_DEB_DIR:-}"
REPO_DIR="${REPO_DIR:-/srv/bizzadrive-repo}"
DIST="${DIST:-trixie}"
INSTALL_BUILD_DEPS="${INSTALL_BUILD_DEPS:-auto}"
PUBLISH_REPO="${PUBLISH_REPO:-auto}"

if [ -z "$OMV_DEB_DIR" ]; then
    if [ -d "$BASE_DIR/openmediavault/deb" ]; then
        OMV_DEB_DIR="$BASE_DIR/openmediavault/deb"
    elif [ -d "$BASE_DIR/../openmediavault/deb" ]; then
        OMV_DEB_DIR="$BASE_DIR/../openmediavault/deb"
    else
        OMV_DEB_DIR="$BASE_DIR/openmediavault/deb"
    fi
fi

is_root=0
if [ "$(id -u)" -eq 0 ]; then
    is_root=1
fi

if [ "$INSTALL_BUILD_DEPS" = "auto" ]; then
    if [ "$is_root" -eq 1 ]; then
        INSTALL_BUILD_DEPS=yes
    else
        INSTALL_BUILD_DEPS=no
    fi
fi

if [ "$PUBLISH_REPO" = "auto" ]; then
    if [ "$is_root" -eq 1 ]; then
        PUBLISH_REPO=yes
    else
        PUBLISH_REPO=no
    fi
fi

echo "[*] BizzaDrive Full OMV Build"
echo "[*] BASE_DIR=$BASE_DIR"
echo "[*] OMV_DEB_DIR=$OMV_DEB_DIR"

if [ ! -d "$OMV_DEB_DIR" ]; then
    echo "[!] OMV deb directory not found: $OMV_DEB_DIR"
    exit 1
fi

if ! command -v dpkg-buildpackage >/dev/null 2>&1; then
    echo "[!] Missing command: dpkg-buildpackage"
    exit 1
fi

if [ "$INSTALL_BUILD_DEPS" = "yes" ] && ! command -v apt >/dev/null 2>&1; then
    echo "[!] Missing command: apt (required because INSTALL_BUILD_DEPS=yes)"
    exit 1
fi

cd "$OMV_DEB_DIR"

for pkgdir in */; do
    if [ -f "$pkgdir/debian/control" ]; then
        cd "$pkgdir"

        if [ "$INSTALL_BUILD_DEPS" = "yes" ]; then
            echo "[*] Installing build-deps for $pkgdir"
            apt build-dep -y . || true
        else
            echo "[*] Skipping build-deps for $pkgdir (INSTALL_BUILD_DEPS=$INSTALL_BUILD_DEPS)"
        fi

        echo "[*] Building $pkgdir"
        dpkg-buildpackage -us -uc -b

        cd "$OMV_DEB_DIR"
    fi
done

if [ "$PUBLISH_REPO" != "yes" ]; then
    echo "[*] Skipping publish step (PUBLISH_REPO=$PUBLISH_REPO)"
    echo "[*] Done."
    exit 0
fi

if ! command -v reprepro >/dev/null 2>&1; then
    echo "[!] Missing command: reprepro (required because PUBLISH_REPO=yes)"
    exit 1
fi

if [ ! -d "$REPO_DIR" ]; then
    echo "[!] Repo directory not found: $REPO_DIR"
    exit 1
fi

echo "[*] Publishing packages..."

for pkg in "$OMV_DEB_DIR"/*.deb; do
    [ -f "$pkg" ] || continue

    PKG_NAME=$(dpkg-deb -f "$pkg" Package)

    echo "  -> Removing existing $PKG_NAME (if any)"
    reprepro -b "$REPO_DIR" remove "$DIST" "$PKG_NAME" || true

    echo "  -> Including $pkg"
    reprepro -b "$REPO_DIR" includedeb "$DIST" "$pkg"
done

echo "[*] Done."
