#!/bin/zsh
set -euo pipefail

CONFIGURATION="${1:-debug}"
ROOT_DIR="${0:A:h:h}"
INSTALL_DIR="${IAPP_INSTALL_DIR:-${HOME}/Applications}"
APP_PATH="$INSTALL_DIR/iapp.app"

"$ROOT_DIR/scripts/bundle.sh" "$CONFIGURATION"
mkdir -p "$INSTALL_DIR"
osascript -e 'tell application id "com.iapp.launcher" to quit' >/dev/null 2>&1 || true
rm -rf "$APP_PATH"
ditto "$ROOT_DIR/dist/iapp.app" "$APP_PATH"
open "$APP_PATH"
print "Installed and opened $APP_PATH"
