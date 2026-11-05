#!/usr/bin/env bash
# Builds build/Wiggle.app (release, ad-hoc signed).
#
# Env vars:
#   VERSION=1.2.3   set CFBundleShortVersionString / CFBundleVersion
#   UNIVERSAL=1     build for arm64 + x86_64 (requires full Xcode)
set -euo pipefail
cd "$(dirname "$0")/.."

ARGS=(-c release)
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  ARGS+=(--arch arm64 --arch x86_64)
fi

swift build "${ARGS[@]}"
BIN_DIR="$(swift build "${ARGS[@]}" --show-bin-path)"

APP="build/Wiggle.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/Wiggle" "$APP/Contents/MacOS/Wiggle"
cp Resources/Info.plist "$APP/Contents/Info.plist"

if [[ -n "${VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
fi

codesign --force --sign - "$APP"

echo "Built $APP"
lipo -info "$APP/Contents/MacOS/Wiggle"
echo "Install with: cp -R $APP /Applications/"
