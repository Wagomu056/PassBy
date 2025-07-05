#!/bin/bash

# PassBy iOS Framework Build Script
# Unified build script for iOS development and release builds

set -e  # Exit on any error

# Default values
BUILD_TYPE="Release"
BUILD_MODE="release"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev|--development)
            BUILD_TYPE="Debug"
            BUILD_MODE="dev"
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            BUILD_MODE="release"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dev, --development  Build for development (Debug mode)"
            echo "  --release             Build for release (Release mode, default)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                   # Release build (default)"
            echo "  $0 --release         # Release build"
            echo "  $0 --dev             # Development build"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build"

echo "🚀 Building PassBy Framework for iOS..."
echo "📋 Build mode: $BUILD_MODE ($BUILD_TYPE)"
echo "📍 Project root: $PROJECT_ROOT"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake for iOS
cmake \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DBUILD_TESTING=OFF \
    "$PROJECT_ROOT"

# Build
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

# Verify the binary
echo ""
echo "📋 Framework info:"
file "$BUILD_DIR/PassBy.framework/PassBy"

echo ""
echo "✅ PassBy.framework successfully built!"
echo "📍 Location: $BUILD_DIR/PassBy.framework"
echo "🔸 Build type: $BUILD_TYPE"
echo "🔸 Architecture: arm64 (iOS devices)"

if [ "$BUILD_MODE" = "dev" ]; then
    echo "🔸 This is a development build (faster compilation, debug info included)"
else
    echo "🔸 This is a release build (optimized for production)"
fi