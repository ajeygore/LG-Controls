#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "=================================================="
echo "🖥️  LG Monitor Control: Automated Setup & Build"
echo "=================================================="

# 1. Check Operating System
OS="$(uname -s)"
if [ "$OS" != "Darwin" ]; then
    echo "❌ Error: This tool requires macOS. Detected: $OS"
    exit 1
fi

# 2. Check Architecture
ARCH="$(uname -m)"
if [ "$ARCH" != "arm64" ]; then
    echo "⚠️  Warning: Apple Silicon (arm64) is required for native DDC/CI IOAVService."
    echo "    Detected architecture: $ARCH"
fi

# 3. Check Xcode Command Line Tools
echo "🔍 Checking developer tools..."
if ! xcode-select -p >/dev/null 2>&1; then
    echo "⬇️  Xcode Command Line Tools not found. Requesting installation..."
    xcode-select --install
    echo "⏳ Please complete the Xcode Command Line Tools installation prompt and rerun this script."
    exit 1
fi
echo "   ✓ Developer tools found at: $(xcode-select -p)"

# 4. Check for Swift and Clang
if ! command -v swiftc >/dev/null 2>&1 || ! command -v clang >/dev/null 2>&1; then
    echo "❌ Error: swiftc or clang compiler not found in PATH."
    exit 1
fi
echo "   ✓ Swift compiler: $(swiftc --version | head -n 1)"
echo "   ✓ Clang compiler: $(clang --version | head -n 1)"

# 5. Check Homebrew and optional tools
if command -v brew >/dev/null 2>&1; then
    echo "   ✓ Homebrew detected."
    # Check if create-dmg can be installed for prettier DMG styling
    if ! command -v create-dmg >/dev/null 2>&1; then
        echo "💡 Tip: You can run 'brew install create-dmg' for custom DMG window styling."
    fi
else
    echo "ℹ️  Homebrew not detected (optional, not strictly required)."
fi

# 6. Build the Application and CLI
echo ""
echo "🔨 Compiling LG Control App & CLI tool..."
"$DIR/Scripts/build.sh"

# 7. Package DMG
echo ""
echo "💿 Creating DMG installer package..."
"$DIR/Scripts/package_dmg.sh"

# 8. Check for --install argument
INSTALL_APP=false
for arg in "$@"; do
    if [ "$arg" == "--install" ] || [ "$arg" == "-i" ]; then
        INSTALL_APP=true
    fi
done

if [ "$INSTALL_APP" = true ]; then
    echo ""
    echo "📲 Installing LG Control to /Applications..."
    rm -rf "/Applications/LG Control.app"
    cp -R "$DIR/build/LG Control.app" "/Applications/LG Control.app"
    
    # Symlink CLI
    if [ -d "/opt/homebrew/bin" ] && [ -w "/opt/homebrew/bin" ]; then
        ln -sf "$DIR/bin/lg-control" "/opt/homebrew/bin/lg-control"
        echo "   ✓ Symlinked CLI to /opt/homebrew/bin/lg-control"
    elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
        ln -sf "$DIR/bin/lg-control" "/usr/local/bin/lg-control"
        echo "   ✓ Symlinked CLI to /usr/local/bin/lg-control"
    fi
fi

# 9. Verify Hardware Connection
echo ""
echo "🔍 Testing hardware communication..."
if "$DIR/bin/lg-control" status >/dev/null 2>&1; then
    echo "✅ Success! Detected connected monitor:"
    "$DIR/bin/lg-control" status
else
    echo "ℹ️  No external DDC monitor currently detected (or monitor DDC/CI is disabled)."
    echo "   Make sure your display is connected and DDC/CI is toggled ON in its OSD settings."
fi

echo ""
echo "=================================================="
echo "🎉 Build Complete!"
echo "   • App Bundle:  build/LG Control.app"
echo "   • DMG Package: build/LG-Control.dmg"
echo "   • CLI Tool:    bin/lg-control"
echo "=================================================="
