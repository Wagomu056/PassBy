#!/bin/bash

# PassBy iOS Framework Development Build Script
# Quick build for development (device only, faster build)

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build"

echo "🛠️  Quick iOS Framework build for development..."

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake for iOS device only
cmake \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTING=OFF \
    "$PROJECT_ROOT"

# Build
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

echo ""
echo "✅ Development build complete!"
echo "📍 Location: $BUILD_DIR/PassBy.framework"
echo ""
echo "Note: This build is for iOS devices only (faster for development)."
echo "Use build_ios_framework.sh for universal framework."