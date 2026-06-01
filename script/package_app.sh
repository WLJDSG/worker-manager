#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="WorkerManager"
BUNDLE_ID="com.wenlanjun.worker-manager"
VERSION="${VERSION:-1.0.0}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
PACKAGE_ROOT="$DIST_DIR/pkg-root"
SCRIPTS_DIR="$DIST_DIR/pkg-scripts"
PKG_PATH="$DIST_DIR/$APP_NAME.pkg"

"$ROOT_DIR/script/build_app_bundle.sh" >/dev/null

rm -rf "$PACKAGE_ROOT" "$SCRIPTS_DIR" "$PKG_PATH"
mkdir -p "$PACKAGE_ROOT/Applications" "$SCRIPTS_DIR"
cp -R "$APP_DIR" "$PACKAGE_ROOT/Applications/"

cat > "$SCRIPTS_DIR/postinstall" <<'SCRIPT'
#!/bin/sh
set -eu

APP_SKILL="/Applications/WorkerManager.app/Contents/Resources/CodexSkills/worker-manager"
CONSOLE_USER="$(/usr/bin/stat -f "%Su" /dev/console || true)"

if [ -z "$CONSOLE_USER" ] || [ "$CONSOLE_USER" = "root" ]; then
  exit 0
fi

USER_HOME="$(/usr/bin/dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
if [ -z "$USER_HOME" ] || [ ! -d "$APP_SKILL" ]; then
  exit 0
fi

DEST_DIR="$USER_HOME/.codex/skills/worker-manager"
if [ -f "$DEST_DIR/SKILL.md" ]; then
  exit 0
fi

/bin/mkdir -p "$DEST_DIR"
/bin/cp -R "$APP_SKILL/." "$DEST_DIR/"
/usr/sbin/chown -R "$CONSOLE_USER" "$USER_HOME/.codex" 2>/dev/null || true

exit 0
SCRIPT
chmod +x "$SCRIPTS_DIR/postinstall"

/usr/bin/pkgbuild \
  --root "$PACKAGE_ROOT" \
  --scripts "$SCRIPTS_DIR" \
  --identifier "$BUNDLE_ID" \
  --version "$VERSION" \
  --install-location "/" \
  "$PKG_PATH"

echo "$PKG_PATH"
