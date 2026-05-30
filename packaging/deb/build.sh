#!/bin/bash
# Build a .deb package for thermal-control
set -euo pipefail

VERSION="0.1.0"
PKG="thermal-control"
ARCH="all"
BUILD_DIR="${PKG}_${VERSION}_${ARCH}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/../.."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"

cp "$REPO_ROOT/thermal-control" "$BUILD_DIR/usr/local/bin/thermal-control"
chmod 755 "$BUILD_DIR/usr/local/bin/thermal-control"

cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PKG
Version: $VERSION
Architecture: $ARCH
Maintainer: cofuente <cofuente@users.noreply.github.com>
Description: Lightweight thermal monitor with desktop alerts
 thermal-control watches CPU and GPU temperatures via Linux hwmon sensors
 and notifies you when they cross a threshold. Choose to switch to
 balanced power mode or dismiss.
Depends: zenity, libnotify-bin, power-profiles-daemon
Section: utils
Priority: optional
Homepage: https://github.com/cofuente/thermal-control
EOF

dpkg-deb --build --root-owner-group "$BUILD_DIR"
echo "Built: ${BUILD_DIR}.deb"
