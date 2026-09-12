#!/usr/bin/env bash
set -e

echo "=== JioGenie Vercel Build Script ==="

# Check if Flutter is already installed in environment
if command -v flutter &> /dev/null; then
  echo "Found Flutter in environment:"
  flutter --version
else
  echo "Installing Flutter SDK (stable branch)..."
  if [ ! -d "_flutter" ]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git _flutter
  fi
  export PATH="$PATH:$(pwd)/_flutter/bin"
  flutter --version
fi

echo "Building Flutter Web application..."
cd flutter_app
flutter pub get
flutter build web --release

echo "=== Build finished successfully! ==="
