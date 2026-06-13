#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="WorkerManager"
PRODUCT_NAME="WorkerManagerApp"
BUNDLE_ID="com.wenlanjun.worker-manager"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BUILD_CONFIG="${BUILD_CONFIG:-release}"

cd "$ROOT_DIR"

HOME="${HOME:-/private/tmp/worker-manager-home}" \
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/worker-manager-module-cache}" \
swift build --configuration "$BUILD_CONFIG" --product "$PRODUCT_NAME" --disable-sandbox

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/$BUILD_CONFIG/$PRODUCT_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.developer-tools</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

BUNDLE_NAME="WorkerManager_WorkerManagerApp.bundle"
if [ -d "$ROOT_DIR/.build/$BUILD_CONFIG/$BUNDLE_NAME" ]; then
  rm -rf "$APP_DIR/$BUNDLE_NAME"
  cp -R "$ROOT_DIR/.build/$BUILD_CONFIG/$BUNDLE_NAME" "$APP_DIR/"
fi

if [ -d "$ROOT_DIR/.build/$BUILD_CONFIG/WorkerManagerApp_WorkerManagerApp.resources" ]; then
  cp -R "$ROOT_DIR/.build/$BUILD_CONFIG/WorkerManagerApp_WorkerManagerApp.resources/." "$RESOURCES_DIR/"
fi

if [ -d "$ROOT_DIR/WorkerManagerApp/Sources/WorkerManagerApp/Resources/CodexSkills" ]; then
  mkdir -p "$RESOURCES_DIR/CodexSkills"
  cp -R "$ROOT_DIR/WorkerManagerApp/Sources/WorkerManagerApp/Resources/CodexSkills/." "$RESOURCES_DIR/CodexSkills/"
fi

echo "$APP_DIR"
