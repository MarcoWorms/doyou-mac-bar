#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="DOYOU Radio"
EXECUTABLE_NAME="DOYOUMenuBarRadio"
BUILD_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-13.0}"
ARCH="$(uname -m)"
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

swiftc \
  -O \
  -sdk "$SDKROOT" \
  -target "$ARCH-apple-macosx$DEPLOYMENT_TARGET" \
  -framework AppKit \
  -framework AVFoundation \
  "$ROOT_DIR/Sources/DOYOUMenuBarRadio/main.swift" \
  -o "$MACOS_DIR/$EXECUTABLE_NAME"

xattr -cr "$APP_BUNDLE"
codesign --force --sign - --timestamp=none "$APP_BUNDLE" >/dev/null

echo "Built app bundle at: $APP_BUNDLE"
