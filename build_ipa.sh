#!/bin/bash
set -euo pipefail

# ==============================================================================
# ReagentKit IPA Build Script
# Auto-generates a unique build number using ms-precision timestamp
# to avoid App Store Connect "duplicate build number" errors forever.
# ==============================================================================

BUILD_NAME=$(awk '/^version:/ { print $2; exit }' pubspec.yaml)
BUILD_NAME="${BUILD_NAME%%+*}"

# Generate unique build number: ms timestamp since epoch
BUILD_NUMBER=$(python3 -c 'import time; print(int(time.time() * 1000))')

echo "📦 Building IPA: $BUILD_NAME ($BUILD_NUMBER)"

flutter build ipa --release \
  --build-name "$BUILD_NAME" \
  --build-number "$BUILD_NUMBER" \
  --export-options-plist=ios/Runner/ExportOptions.plist \
  "$@"

echo "✅ IPA built: build/ios/ipa/ReagentKit.ipa"
echo "🔢 Build number: $BUILD_NUMBER"
