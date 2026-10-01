#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

BUILD_DIR="$DIR/build"
APP_NAME="LG Control.app"
APP_PATH="$BUILD_DIR/$APP_NAME"
DMG_NAME="LG-Control.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
VOL_NAME="LG Monitor Control"

# 1. Ensure the app is built
if [ ! -d "$APP_PATH" ]; then
    echo "📦 App not found in build directory. Building now..."
    "$DIR/Scripts/build.sh"
fi

echo "💿 Packaging $DMG_NAME..."

# 2. Prepare staging directory
STAGING_DIR="$BUILD_DIR/dmg_staging"
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

# 3. Copy app into staging
cp -R "$APP_PATH" "$STAGING_DIR/"

# 4. Create symlink to /Applications for easy drag-and-drop
ln -s /Applications "$STAGING_DIR/Applications"

# 5. Add custom icon to DMG volume if available
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns"
fi

# 6. Check if create-dmg is available for custom window layout, otherwise use native hdiutil
if command -v create-dmg >/dev/null 2>&1; then
    echo "🎨 Using create-dmg for styled installer..."
    create-dmg \
        --volname "$VOL_NAME" \
        --volicon "$DIR/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME" 175 190 \
        --hide-extension "$APP_NAME" \
        --app-drop-link 425 190 \
        --no-internet-enable \
        "$DMG_PATH" \
        "$STAGING_DIR" || true
fi

# Fallback to native hdiutil if create-dmg was not used or failed
if [ ! -f "$DMG_PATH" ]; then
    echo "🔧 Creating compressed DMG via native hdiutil..."
    hdiutil create \
        -volname "$VOL_NAME" \
        -srcfolder "$STAGING_DIR" \
        -ov \
        -format UDZO \
        "$DMG_PATH"
fi

# 7. Clean up staging directory
rm -rf "$STAGING_DIR"

echo "✅ DMG package successfully created at: $DMG_PATH"
ls -lh "$DMG_PATH"
