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

```bash
# Build the library
mkdir build && cd build
cmake ..
make

# Run tests
make test
# or
ctest

# Run tests with verbose output
ctest --verbose

# For iOS (requires Xcode)
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake

# For Android (requires NDK)
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake
```

## Architecture

- **Core C++ Library**: Contains shared business logic for BLE encounter management
- **Platform Wrappers**: iOS and Android specific implementations that bridge to the C++ core
- **Simple API**: Currently provides basic scanning start/stop functionality with room for expansion