#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Info.plist")"
DMG_PATH="${1:-$ROOT_DIR/dist/iapp-${VERSION}.dmg}"
PROFILE="${IAPP_NOTARY_PROFILE:-iapp-notary}"

[[ -f "$DMG_PATH" ]] || { print -u2 "DMG not found: $DMG_PATH"; exit 66; }
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl -a -vvv -t open --context context:primary-signature "$DMG_PATH"
print "Notarized release ready: $DMG_PATH"
