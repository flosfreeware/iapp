#!/bin/zsh
set -euo pipefail

APP_PATH="${IAPP_INSTALL_DIR:-${HOME}/Applications}/iapp.app"
osascript -e 'tell application id "com.iapp.launcher" to quit' >/dev/null 2>&1 || true
rm -rf "$APP_PATH"
print "Removed $APP_PATH"
