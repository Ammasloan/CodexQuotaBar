#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexQuotaBar.app"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME"
MACOS_DIR="$APP_DIR/Contents/MacOS"

cd "$ROOT_DIR"
swift build -c release

mkdir -p "$MACOS_DIR"
cp "$BUILD_DIR/CodexQuotaBar" "$MACOS_DIR/CodexQuotaBar"
chmod +x "$MACOS_DIR/CodexQuotaBar"

/usr/bin/plutil -replace CFBundleDevelopmentRegion -string en "$APP_DIR/Contents/Info.plist" 2>/dev/null || true

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CodexQuotaBar</string>
    <key>CFBundleIdentifier</key>
    <string>local.codex.quota.bar</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CodexQuotaBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Built $APP_DIR"
