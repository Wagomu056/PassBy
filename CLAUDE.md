# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Top-Level Rules

**You must think exclusively in English**. However, you are required to **respond in Japanese**.

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
├── build_ios.sh           # iOS framework build script (unified)
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
# Development build (Debug mode)
./build_ios.sh --dev

# Release build (optimized, default)
./build_ios.sh
./build_ios.sh --release
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

## PassBy Class Usage Examples

### Basic Initialization and Usage

```cpp
#include <PassBy/PassBy.h>
#include <PassBy/PassByTypes.h>

// 1. Get singleton instance
PassBy::PassByManager& manager = PassBy::PassByManager::getInstance();

// 2. Set device discovery callback
manager.setDeviceDiscoveredCallback([](const PassBy::DeviceInfo& device) {
    // Handle device discovery
    printf("Device discovered: %s\n", device.uuid.c_str());
});

// 3. Start BLE scanning
// Filter by specific service UUID
std::string serviceUUID = "12345678-1234-1234-1234-123456789ABC";
if (manager.startScanning(serviceUUID)) {
    printf("Started scanning for service: %s\n", serviceUUID.c_str());
} else {
    printf("Failed to start scanning\n");
}

// Or scan all devices
if (manager.startScanning()) {
    printf("Started scanning all devices\n");
}

// 4. Get discovered devices
auto devices = manager.getDiscoveredDevices();
printf("Found %zu devices\n", devices.size());
for (const auto& uuid : devices) {
    printf("Device: %s\n", uuid.c_str());
}

// 5. Stop scanning
if (manager.stopScanning()) {
    printf("Stopped scanning\n");
}
```

### iOS (Objective-C++) Usage Example

```objc
// Implementation example in ViewController.mm

#import "ViewController.h"
#include <PassBy/PassBy.h>
#include <PassBy/PassByTypes.h>

@implementation ViewController {
    PassBy::PassByManager* _passbyManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get singleton instance
    _passbyManager = &PassBy::PassByManager::getInstance();
    
    // Set device discovery callback (executed on main thread)
    _passbyManager->setDeviceDiscoveredCallback([self](const PassBy::DeviceInfo& device) {
        PassBy::DeviceInfo deviceCopy = device;
        // Core Bluetooth callbacks are executed on background thread,
        // so dispatch to main queue for UI updates
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onDeviceDiscovered:deviceCopy];
        });
    });
}

- (void)startScanning {
    // Get service UUID from text field
    NSString *serviceUUID = self.serviceUUIDTextField.text;
    std::string serviceUUIDString = "";
    if (serviceUUID && serviceUUID.length > 0) {
        serviceUUIDString = std::string([serviceUUID UTF8String]);
    }
    
    // Start scanning
    if (_passbyManager->startScanning(serviceUUIDString)) {
        if (serviceUUID && serviceUUID.length > 0) {
            self.statusLabel.text = [NSString stringWithFormat:@"PassBy Status: Scanning for %@", serviceUUID];
            NSLog(@"Started BLE scanning for service: %@", serviceUUID);
        } else {
            self.statusLabel.text = @"PassBy Status: Scanning all devices";
            NSLog(@"Started BLE scanning for all devices");
        }
    } else {
        NSLog(@"Failed to start BLE scanning");
    }
}

- (void)stopScanning {
    if (_passbyManager && _passbyManager->stopScanning()) {
        self.statusLabel.text = @"PassBy Status: Stopped";
        NSLog(@"Stopped BLE scanning");
    } else {
        NSLog(@"Failed to stop BLE scanning");
    }
}

- (void)getDiscoveredDevices {
    if (_passbyManager) {
        auto discoveredDevices = _passbyManager->getDiscoveredDevices();
        NSMutableString *resultText = [[NSMutableString alloc] init];
        
        [resultText appendFormat:@"Total discovered devices: %lu\n\n", (unsigned long)discoveredDevices.size()];
        
        if (discoveredDevices.empty()) {
            [resultText appendString:@"No devices discovered yet."];
        } else {
            [resultText appendString:@"Device UUIDs:\n"];
            for (const auto& uuid : discoveredDevices) {
                [resultText appendFormat:@"• %s\n", uuid.c_str()];
            }
        }
        
    } else {
        NSLog(@"Error: PassBy manager not initialized");
    }
}

- (void)onDeviceDiscovered:(const PassBy::DeviceInfo&)device {
    // Safe UUID conversion
    NSString *deviceUUID = @"<INVALID UUID>";
    if (!device.uuid.empty()) {
        const char* cString = device.uuid.c_str();
        if (cString && strlen(cString) > 0) {
            deviceUUID = [NSString stringWithUTF8String:cString];
        }
    }
    
    NSString *appState = [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground ? @"Background" : @"Foreground";
    
    NSLog(@"Device discovered (%@): %@", appState, deviceUUID);
}

@end
```

### Main API Reference

#### PassByManager (Singleton)
- `getInstance()`: Get instance
- `startScanning(serviceUUID)`: Start BLE scanning
- `stopScanning()`: Stop BLE scanning
- `isScanning()`: Check if currently scanning
- `setDeviceDiscoveredCallback()`: Set device discovery callback
- `getDiscoveredDevices()`: Get list of discovered device UUIDs
- `clearDiscoveredDevices()`: Clear discovered devices list
- `getCurrentServiceUUID()`: Get current service UUID (empty string when not scanning)
- `getVersion()`: Get library version

#### Implementation Notes
- PassByManager is a singleton, so the same instance can be obtained from multiple locations
- Device discovery callbacks are executed on background threads, so dispatch to main thread for UI updates
- Pass empty string for service UUID to scan all devices
- iOS uses Core Bluetooth framework (requires background mode capability)

### Notes for Development
- Always run tests before committing changes: `./build_and_test.sh`
- iOS framework build: `./build_ios_framework.sh`
- Test builds are configured to run serially to avoid singleton conflicts
- Use `PASSBY_TESTING_ENABLED` define for test-only functionality