#!/bin/bash

# PassBy Test Build and Execution Script
# This script builds the library for testing on macOS and runs unit tests

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
TEST_BUILD_DIR="$PROJECT_ROOT/build_test"

echo "🧪 Building PassBy for Testing..."
echo "Project root: $PROJECT_ROOT"
echo "Test build directory: $TEST_BUILD_DIR"

# Clean and create test build directory
echo "🗑️  Cleaning previous test build..."
rm -rf "$TEST_BUILD_DIR"
mkdir -p "$TEST_BUILD_DIR"
cd "$TEST_BUILD_DIR"

# Configure with CMake for macOS testing
echo "⚙️  Configuring CMake for testing..."
cmake \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTING=ON \
    "$PROJECT_ROOT"

# Build
echo "🔨 Building library and tests..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

echo ""
echo "✅ Build completed successfully!"
echo ""

# Run tests
echo "🚀 Running unit tests..."
echo "=========================="
make test

echo ""
echo "📊 Running tests with detailed output..."
echo "========================================"
ctest --verbose

echo ""
echo "✨ All tests completed!"
echo "📍 Test build location: $TEST_BUILD_DIR"