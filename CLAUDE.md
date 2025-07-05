# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

PassBy is a cross-platform mobile game library for BLE (Bluetooth Low Energy) encounter history management. The library supports both iOS and Android platforms with shared C++ core logic.

## Project Structure

```
PassBy/
├── include/PassBy/         # Public headers
├── src/
│   ├── cpp/               # Shared C++ implementation
│   ├── internal/          # Internal headers (PlatformFactory, PlatformInterface)
│   └── platform/ios/      # iOS platform factory implementation
├── ios/PassBy/            # iOS-specific wrapper code (BLE manager)
├── tests/                 # Test files and mocks
├── iOSPassBySample/       # iOS sample application
├── build_and_test.sh      # Build script for testing
├── build_ios_dev.sh       # iOS development build script
├── build_ios_framework.sh # iOS framework build script
├── run_tests.sh           # Test execution script
└── CMakeLists.txt         # Build configuration
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

## Current Implementation Status

### ✅ Completed Features
- Singleton-based PassByManager with thread-safe implementation
- iOS BLE scanning and advertising support with Core Bluetooth
- Service UUID filtering for targeted device discovery
- Comprehensive test suite (14 test cases) with proper isolation
- iOS sample application with UI
- Cross-platform build system using CMake

### 📋 Future Development Roadmap

#### 1. バックグラウンド対応 (Background Support)
- **Goal**: Enable BLE encounter recording even when app is in background
- **iOS**: Implement Core Bluetooth background modes
- **Android**: Implement foreground service for background BLE operations
- **Priority**: High - Essential for real-world usage

#### 2. すれ違い情報の拡充 (Enhanced Encounter Data)
- **Current**: Only stores device UUID
- **Enhancement**: Add encounter timestamp recording
- **Implementation**: Extend `DeviceInfo` structure to include timestamp
- **API Impact**: Update callback interface and storage methods
- **Priority**: Medium - Improves data richness

#### 3. Android対応 (Android Platform Support)
- **Current**: iOS implementation complete and tested
- **Next**: Implement Android BLE wrapper using Android BLE APIs
- **Architecture**: Follow same pattern as iOS platform implementation
- **Testing**: Create Android sample app equivalent to iOS version
- **Priority**: Medium - Completes cross-platform support

### Notes for Development
- Always run tests before committing changes: `./build_and_test.sh`
- iOS framework build: `./build_ios_framework.sh`
- Test builds are configured to run serially to avoid singleton conflicts
- Use `PASSBY_TESTING_ENABLED` define for test-only functionality