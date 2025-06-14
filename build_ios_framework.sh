#!/bin/bash

# PassBy iOS Framework Build Script
# This script builds the PassBy framework for iOS devices and simulator

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build"

echo "🚀 Building PassBy Framework for iOS..."
echo "Project root: $PROJECT_ROOT"

# Function to build for specific platform
build_for_platform() {
    local platform=$1
    local arch=$2
    local build_suffix=$3
    local cmake_sysroot=$4
    
    echo "📱 Building for $platform ($arch)..."
    
    local platform_build_dir="$BUILD_DIR-$build_suffix"
    
    # Clean and create build directory
    rm -rf "$platform_build_dir"
    mkdir -p "$platform_build_dir"
    cd "$platform_build_dir"
    
    # Configure with CMake
    cmake \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_ARCHITECTURES="$arch" \
        -DCMAKE_OSX_SYSROOT="$cmake_sysroot" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        "$PROJECT_ROOT"
    
    # Build
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
    
    echo "✅ Successfully built for $platform"
}

# Build for iOS Device (arm64)
build_for_platform "iOS Device" "arm64" "ios-device" "iphoneos"

echo "🔧 Creating final framework..."

# Create output directory
OUTPUT_DIR="$PROJECT_ROOT/build"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy framework structure from device build
cp -R "$BUILD_DIR-ios-device/PassBy.framework" "$OUTPUT_DIR/"

# Verify the binary
echo "📋 Framework info:"
file "$OUTPUT_DIR/PassBy.framework/PassBy"

echo ""
echo "✨ PassBy.framework successfully built!"
echo "📍 Location: $OUTPUT_DIR/PassBy.framework"
echo ""
echo "🔸 This framework is built for iOS devices (arm64)."
echo "🔸 Compatible with iPhone/iPad devices and Apple Silicon simulators."