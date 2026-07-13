#!/usr/bin/env bash
# Builds BreakTime-<version>-x86_64.AppImage from a completed
# `flutter build linux --release`. Run from the repo root.
set -euo pipefail

BUNDLE="build/linux/x64/release/bundle"
APPDIR="build/appimage/BreakTime.AppDir"
VERSION="$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)"
OUT="build/appimage/BreakTime-${VERSION}-x86_64.AppImage"

[ -d "$BUNDLE" ] || { echo "error: run 'flutter build linux --release' first" >&2; exit 1; }

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps"

cp -r "$BUNDLE"/* "$APPDIR/"
cp assets/linux/com.xernai.breaktime.desktop "$APPDIR/"
cp assets/linux/com.xernai.breaktime.svg "$APPDIR/"
cp assets/linux/com.xernai.breaktime.svg \
   "$APPDIR/usr/share/icons/hicolor/scalable/apps/"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/breaktime" "$@"
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
