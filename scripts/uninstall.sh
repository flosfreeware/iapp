#!/bin/zsh
set -euo pipefail

APP_PATH="${IAPP_INSTALL_DIR:-${HOME}/Applications}/iapp.app"
pkill -x iapp >/dev/null 2>&1 || true
rm -rf "$APP_PATH"
print "Removed $APP_PATH"
