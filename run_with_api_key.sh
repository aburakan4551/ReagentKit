#!/bin/bash

# ==============================================================================
# ReagentKit Secure Runner Script
# This script runs the Flutter app with all required API keys injected via dart-define.
# Use this for local development to avoid hardcoding keys in the source.
# ==============================================================================

# Default values for keys (Replace these locally or set as env variables)
# DO NOT COMMIT REAL KEYS TO THIS SCRIPT
GEMINI_KEY="${GEMINI_API_KEY:-YOUR_GEMINI_API_KEY}"
FB_WEB_KEY="${FIREBASE_API_KEY_WEB:-YOUR_WEB_KEY}"
FB_ANDROID_KEY="${FIREBASE_API_KEY_ANDROID:-YOUR_ANDROID_KEY}"
FB_IOS_KEY="${FIREBASE_API_KEY_IOS:-YOUR_IOS_KEY}"
FB_MACOS_KEY="${FIREBASE_API_KEY_MACOS:-YOUR_MACOS_KEY}"
FB_WINDOWS_KEY="${FIREBASE_API_KEY_WINDOWS:-YOUR_WINDOWS_KEY}"

# Check for 'release' or 'debug' mode
MODE=${1:-debug}

echo "🚀 Starting ReagentKit in $MODE mode..."
echo "🔑 Injecting API keys via --dart-define"

flutter run --$MODE \
  --dart-define=GEMINI_API_KEY="$GEMINI_KEY" \
  --dart-define=FIREBASE_API_KEY_WEB="$FB_WEB_KEY" \
  --dart-define=FIREBASE_API_KEY_ANDROID="$FB_ANDROID_KEY" \
  --dart-define=FIREBASE_API_KEY_IOS="$FB_IOS_KEY" \
  --dart-define=FIREBASE_API_KEY_MACOS="$FB_MACOS_KEY" \
  --dart-define=FIREBASE_API_KEY_WINDOWS="$FB_WINDOWS_KEY"
