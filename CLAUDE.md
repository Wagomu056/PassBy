# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

PassBy is a cross-platform mobile game library for BLE (Bluetooth Low Energy) encounter history management. The library supports both iOS and Android platforms with shared C++ core logic.

## Project Structure

```
PassBy/
├── include/PassBy/     # Public headers
├── src/cpp/           # Shared C++ implementation
├── ios/               # iOS-specific wrapper code
├── android/           # Android-specific wrapper code
└── CMakeLists.txt     # Build configuration
```

## Build Commands

### Development Build (macOS/Testing)
```bash
# Build and run tests (recommended)
./build_and_test.sh

# Run tests only (if already built)
./run_tests.sh

# Manual build and test
mkdir build_test && cd build_test
cmake -DBUILD_TESTING=ON ..
make
make test
```

### iOS Framework Build
```bash
# Quick development build (device only)
./build_ios_dev.sh

# Universal framework (device + simulator)
./build_ios_framework.sh
```

### Manual iOS Build
```bash
mkdir build && cd build
cmake -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64 -DBUILD_TESTING=OFF ..
make
```

## Architecture

- **Core C++ Library**: Contains shared business logic for BLE encounter management
- **Platform Wrappers**: iOS and Android specific implementations that bridge to the C++ core
- **Simple API**: Currently provides basic scanning start/stop functionality with room for expansion