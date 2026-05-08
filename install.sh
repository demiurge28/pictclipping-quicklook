#!/bin/bash
set -euo pipefail

BUNDLE_NAME="PictClippingQL.qlgenerator"
INSTALL_DIR="$HOME/Library/QuickLook"
BUILD_DIR="$(mktemp -d)"
BUNDLE="$BUILD_DIR/$BUNDLE_NAME"
EXEC_DIR="$BUNDLE/Contents/MacOS"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cleanup() { rm -rf "$BUILD_DIR"; }
trap cleanup EXIT

echo "PictClipping Quick Look — Installer"
echo "===================================="
echo ""

# Check for compiler
if ! command -v clang &>/dev/null; then
    echo "Error: clang not found."
    echo "Install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Build
echo "Building universal binary (arm64 + x86_64)..."
mkdir -p "$EXEC_DIR"
clang -O2 -fobjc-arc -mmacosx-version-min=12.0 -arch arm64 -arch x86_64 -Wno-deprecated-declarations \
    -framework Foundation -framework AppKit -framework QuickLook -framework CoreServices \
    -bundle -o "$EXEC_DIR/PictClippingQL" \
    "$SCRIPT_DIR/src/main.c" "$SCRIPT_DIR/src/GeneratePreview.m" 2>&1
cp "$SCRIPT_DIR/src/Info.plist" "$BUNDLE/Contents/Info.plist"
echo "  ✓ Built"

# Install
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$BUNDLE_NAME"
cp -R "$BUNDLE" "$INSTALL_DIR/$BUNDLE_NAME"
echo "  ✓ Installed to $INSTALL_DIR/$BUNDLE_NAME"

# Reset Quick Look
qlmanage -r &>/dev/null || true
echo "  ✓ Quick Look cache reset"

echo ""
echo "Done! Select a .pictClipping file in Finder and press Space to preview."
