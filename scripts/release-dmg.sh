#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_PATH="$ROOT_DIR/dist/iapp.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Info.plist")"
DMG_PATH="$ROOT_DIR/dist/iapp-${VERSION}.dmg"
STAGING_DIR="$(mktemp -d /private/tmp/iapp-dmg.XXXXXX)"
trap 'rm -rf "$STAGING_DIR"' EXIT

"$ROOT_DIR/scripts/bundle.sh" release
ditto "$APP_PATH" "$STAGING_DIR/iapp.app"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create -volname "iapp" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null
print "Created $DMG_PATH"
print "Next: make notarize-dmg"
