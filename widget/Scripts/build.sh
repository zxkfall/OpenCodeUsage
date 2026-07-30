#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
XCODE_PROJ="$PROJECT_DIR/OpenCodeUsage.xcodeproj"
APP_NAME="OpenCode Usage"
BUILD_DIR="$PROJECT_DIR/.build"
DMG_NAME="OpenCodeUsage.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"

echo "==> Building $APP_NAME ..."

cd "$PROJECT_DIR"

# Generate Xcode project
python3 "$SCRIPT_DIR/generate_xcode.py"

# Build Release
xcodebuild \
    -project "$XCODE_PROJ" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build 2>&1 | grep -E "BUILD|error:" || true

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "ERROR: Build failed"
    exit 1
fi

echo ""
echo "==> Creating DMG..."

# Clean up old
rm -f "$DMG_PATH"

# Create temp DMG
TMP_DMG="$BUILD_DIR/tmp.dmg"
rm -f "$TMP_DMG"

hdiutil create -size 20m -fs HFS+ -volname "$APP_NAME" "$TMP_DMG" > /dev/null
hdiutil attach "$TMP_DMG" -mountpoint /Volumes/"$APP_NAME" > /dev/null

cp -R "$BUILT_APP" /Volumes/"$APP_NAME"/

# Create Applications symlink for drag-to-install
ln -s /Applications /Volumes/"$APP_NAME"/Applications 2>/dev/null || true

hdiutil detach /Volumes/"$APP_NAME" -force > /dev/null
hdiutil convert "$TMP_DMG" -format UDZO -o "$DMG_PATH" > /dev/null
rm -f "$TMP_DMG"

# Clean build dir
rm -rf "$BUILD_DIR"

echo ""
echo "==> Done: $DMG_PATH"
echo ""
echo "To install:"
echo "  open $DMG_PATH"
echo "  Drag '$APP_NAME.app' to Applications"
echo ""
echo "First launch:"
echo "  Click the menu bar icon → Settings (gear)"
echo "  Enter your Workspace ID and auth cookie"
echo ""
echo "Widget:"
echo "  After launching, add widget from Notification Center"
