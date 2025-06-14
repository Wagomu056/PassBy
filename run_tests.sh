#!/bin/bash

# PassBy Test Execution Script
# This script runs tests from existing test build

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
TEST_BUILD_DIR="$PROJECT_ROOT/build_test"

echo "🧪 Running PassBy Tests..."

# Check if test build exists
if [ ! -d "$TEST_BUILD_DIR" ]; then
    echo "❌ Test build directory not found: $TEST_BUILD_DIR"
    echo "💡 Run './build_and_test.sh' first to build tests."
    exit 1
fi

if [ ! -f "$TEST_BUILD_DIR/PassByTests" ]; then
    echo "❌ Test executable not found: $TEST_BUILD_DIR/PassByTests"
    echo "💡 Run './build_and_test.sh' to rebuild tests."
    exit 1
fi

cd "$TEST_BUILD_DIR"

echo "🚀 Running unit tests..."
echo "=========================="
make test

echo ""
echo "📊 Running tests with detailed output..."
echo "========================================"
ctest --verbose

echo ""
echo "✅ All tests completed!"