#!/bin/zsh
set -euo pipefail

CONFIGURATION="${1:-debug}"
ROOT_DIR="${0:A:h:h}"
INSTALL_DIR="${IAPP_INSTALL_DIR:-${HOME}/Applications}"
APP_PATH="$INSTALL_DIR/iapp.app"

"$ROOT_DIR/scripts/bundle.sh" "$CONFIGURATION"
mkdir -p "$INSTALL_DIR"
# Asking AppleScript to quit an app by bundle ID can itself ask LaunchServices to
# launch a missing/stale copy, producing error -600. Stop only an existing binary.
pkill -x iapp >/dev/null 2>&1 || true
sleep 0.2
rm -rf "$APP_PATH"
ditto "$ROOT_DIR/dist/iapp.app" "$APP_PATH"
open -n "$APP_PATH"
print "Installed and opened $APP_PATH"
