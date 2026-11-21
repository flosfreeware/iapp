#!/bin/zsh
set -euo pipefail

CONFIGURATION="${1:-debug}"
if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  print -u2 "Usage: $0 [debug|release]"
  exit 64
fi

ROOT_DIR="${0:A:h:h}"
OUTPUT_DIR="$ROOT_DIR/dist/iapp.app"
BUILD_ARGS=()
[[ "$CONFIGURATION" == "release" ]] && BUILD_ARGS+=(--configuration release)

# Keep personal signing identities out of the repository. A local config makes
# TCC permissions stable across rebuilds because every copy has the same signer.
SIGNING_CONFIG="$ROOT_DIR/.iapp-signing.local"
[[ -f "$SIGNING_CONFIG" ]] && source "$SIGNING_CONFIG"

cd "$ROOT_DIR"
swift build "${BUILD_ARGS[@]}"

BIN_PATH="$(swift build --show-bin-path "${BUILD_ARGS[@]}")/iapp"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Contents/MacOS" "$OUTPUT_DIR/Contents/Resources"
cp "$BIN_PATH" "$OUTPUT_DIR/Contents/MacOS/iapp"
cp "$ROOT_DIR/Info.plist" "$OUTPUT_DIR/Contents/Info.plist"
if [[ -f "$ROOT_DIR/assets/iapp.icns" ]]; then
  cp "$ROOT_DIR/assets/iapp.icns" "$OUTPUT_DIR/Contents/Resources/iapp.icns"
fi

if [[ -n "${IAPP_SIGNING_IDENTITY:-}" ]]; then
  IDENTITY="$IAPP_SIGNING_IDENTITY"
elif [[ "$CONFIGURATION" == "debug" ]]; then
  IDENTITY="${IAPP_DEV_SIGNING_IDENTITY:--}"
else
  IDENTITY="${IAPP_RELEASE_SIGNING_IDENTITY:--}"
fi

codesign --force --sign "$IDENTITY" --timestamp=none "$OUTPUT_DIR"
print "Built $OUTPUT_DIR"
