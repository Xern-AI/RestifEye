#!/usr/bin/env bash
# Builds restifeye_<version>_amd64.deb from a completed
# `flutter build linux --release`. Run from the repo root.
set -euo pipefail

BUNDLE="build/linux/x64/release/bundle"
VERSION="$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)"
PKG="build/deb/restifeye_${VERSION}_amd64"
OUT="${PKG}.deb"

[ -d "$BUNDLE" ] || { echo "error: run 'flutter build linux --release' first" >&2; exit 1; }

rm -rf "$PKG"
mkdir -p "$PKG/DEBIAN"
mkdir -p "$PKG/opt/RestifEye"
mkdir -p "$PKG/usr/bin"
mkdir -p "$PKG/usr/share/applications"
mkdir -p "$PKG/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$PKG/usr/share/metainfo"

# ---- DEBIAN/control ----
cat > "$PKG/DEBIAN/control" <<EOF
Package: restifeye
Version: ${VERSION}
Architecture: amd64
Maintainer: Xernai <xernaitech@gmail.com>
Depends: libgtk-3-0, pipewire
Section: utils
Priority: optional
Homepage: https://github.com/Xern-AI/RestifEye
Description: Break reminders that respect your flow
 RestifEye reminds you to rest your eyes and move at healthy intervals.
 It defers breaks during calls, credits breaks you take on your own,
 warns before taking the screen, and shows an illustrated exercise with
 every break. Local-only analytics and advice. No telemetry.
EOF

# ---- App bundle ----
cp -r "$BUNDLE"/* "$PKG/opt/RestifEye/"

# ---- Symlink so `RestifEye` is on PATH ----
ln -s /opt/RestifEye/RestifEye "$PKG/usr/bin/RestifEye"

# ---- Desktop integration ----
cp assets/linux/com.xernai.restifeye.desktop \
   "$PKG/usr/share/applications/"
cp assets/linux/com.xernai.restifeye.svg \
   "$PKG/usr/share/icons/hicolor/scalable/apps/"
cp assets/linux/com.xernai.restifeye.metainfo.xml \
   "$PKG/usr/share/metainfo/"

# ---- Build ----
dpkg-deb --build --root-owner-group "$PKG"
echo "built: $OUT"
