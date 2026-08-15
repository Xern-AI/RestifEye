#!/usr/bin/env bash
# Builds RestifEye-<version>-x86_64.AppImage from a completed
# `flutter build linux --release`. Run from the repo root.
set -euo pipefail

BUNDLE="build/linux/x64/release/bundle"
APPDIR="build/appimage/RestifEye.AppDir"
VERSION="$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)"
OUT="build/appimage/RestifEye-${VERSION}-x86_64.AppImage"

[ -d "$BUNDLE" ] || { echo "error: run 'flutter build linux --release' first" >&2; exit 1; }

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps" \
         "$APPDIR/usr/share/metainfo"

cp -r "$BUNDLE"/* "$APPDIR/"
cp assets/linux/com.xernai.restifeye.desktop "$APPDIR/"

# Top-level icon MUST be PNG for AppImageHub thumbnail generation.
# appdir-lint warns "Icon is not in PNG format" if only SVG is present.
# Lives in assets/linux/ beside the SVG it is rendered from: docs/ is not a
# packaging input and its copy was deleted, silently breaking the release.
cp assets/linux/com.xernai.restifeye.png "$APPDIR/com.xernai.restifeye.png"

# Keep SVG in hicolor for desktop integration (scalable rendering).
cp assets/linux/com.xernai.restifeye.svg \
   "$APPDIR/usr/share/icons/hicolor/scalable/apps/"

# AppStream metainfo — required by AppImageHub for description/license extraction.
cp assets/linux/com.xernai.restifeye.metainfo.xml \
   "$APPDIR/usr/share/metainfo/"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/RestifEye" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# appimagetool: use the one on PATH (CI installs it) or fetch it.
if ! command -v appimagetool >/dev/null 2>&1; then
  TOOL="build/appimage/appimagetool"
  if [ ! -x "$TOOL" ]; then
    curl -fsSL -o "$TOOL" \
      "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$TOOL"
  fi
  appimagetool() { "$TOOL" "$@"; }
fi

ARCH=x86_64 appimagetool "$APPDIR" "$OUT"
echo "built: $OUT"
