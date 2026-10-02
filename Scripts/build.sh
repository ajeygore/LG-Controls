#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🔨 Building LG Monitor Control..."

BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/LG Control.app"
BIN_DIR="$DIR/bin"

rm -rf "$BUILD_DIR" "$BIN_DIR"
mkdir -p "$BUILD_DIR/objs" "$BIN_DIR"

# 1. Compile Objective-C DDC layer with ARC
echo "📦 Compiling DDC core..."
clang -c DDC/i2c.m -I DDC -fobjc-arc -o "$BUILD_DIR/objs/i2c.o" -Wall
clang -c DDC/ioregistry.m -I DDC -fobjc-arc -o "$BUILD_DIR/objs/ioregistry.o" -Wall
clang -c DDC/DDCManager.m -I DDC -fobjc-arc -o "$BUILD_DIR/objs/DDCManager.o" -Wall

# 2. Build CLI tool
echo "📦 Compiling CLI tool (lg-control)..."
swiftc -O \
    -import-objc-header DDC/DDCBridge.h \
    Sources/CLI.swift \
    "$BUILD_DIR/objs/i2c.o" \
    "$BUILD_DIR/objs/ioregistry.o" \
    "$BUILD_DIR/objs/DDCManager.o" \
    -framework CoreDisplay \
    -framework CoreGraphics \
    -framework IOKit \
    -framework Foundation \
    -o "$BIN_DIR/lg-control"

echo "✅ Built CLI tool at $BIN_DIR/lg-control"

# 3. Build GUI App
echo "📦 Compiling GUI App..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc -O \
    -import-objc-header DDC/DDCBridge.h \
    Sources/MonitorViewModel.swift \
    Sources/ContentView.swift \
    Sources/OSDController.swift \
    Sources/MediaKeyController.swift \
    Sources/AppDelegate.swift \
    Sources/main.swift \
    "$BUILD_DIR/objs/i2c.o" \
    "$BUILD_DIR/objs/ioregistry.o" \
    "$BUILD_DIR/objs/DDCManager.o" \
    -framework CoreDisplay \
    -framework CoreGraphics \
    -framework IOKit \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -o "$APP_BUNDLE/Contents/MacOS/LGControl"

cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Clean extended attributes and sign with stable designated requirement for TCC / Accessibility
xattr -cr "$APP_BUNDLE"
codesign --force --deep -s - -r='designated => identifier "com.user.LGControl"' "$APP_BUNDLE"

echo "✅ Built and signed App Bundle at $APP_BUNDLE"

