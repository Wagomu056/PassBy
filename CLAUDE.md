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

## PassByクラスの使用例

### 基本的な初期化と使用方法

```cpp
#include <PassBy/PassBy.h>
#include <PassBy/PassByTypes.h>

// 1. シングルトンインスタンスの取得
PassBy::PassByManager& manager = PassBy::PassByManager::getInstance();

// 2. デバイス発見コールバックの設定
manager.setDeviceDiscoveredCallback([](const PassBy::DeviceInfo& device) {
    // デバイスが発見されたときの処理
    printf("Device discovered: %s\n", device.uuid.c_str());
});

// 3. BLEスキャニングの開始
// 特定のサービスUUIDで絞り込み
std::string serviceUUID = "12345678-1234-1234-1234-123456789ABC";
if (manager.startScanning(serviceUUID)) {
    printf("Started scanning for service: %s\n", serviceUUID.c_str());
} else {
    printf("Failed to start scanning\n");
}

// または、すべてのデバイスをスキャン
if (manager.startScanning()) {
    printf("Started scanning all devices\n");
}

// 4. 発見されたデバイスの取得
auto devices = manager.getDiscoveredDevices();
printf("Found %zu devices\n", devices.size());
for (const auto& uuid : devices) {
    printf("Device: %s\n", uuid.c_str());
}

// 5. スキャニングの停止
if (manager.stopScanning()) {
    printf("Stopped scanning\n");
}
```

### iOS（Objective-C++）での使用例

```objc
// ViewController.mm での実装例

#import "ViewController.h"
#include <PassBy/PassBy.h>
#include <PassBy/PassByTypes.h>

@implementation ViewController {
    PassBy::PassByManager* _passbyManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // シングルトンインスタンスの取得
    _passbyManager = &PassBy::PassByManager::getInstance();
    
    // デバイス発見コールバックの設定（メインスレッドで実行）
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
    // テキストフィールドからサービスUUIDを取得
    NSString *serviceUUID = self.serviceUUIDTextField.text;
    std::string serviceUUIDString = "";
    if (serviceUUID && serviceUUID.length > 0) {
        serviceUUIDString = std::string([serviceUUID UTF8String]);
    }
    
    // スキャニング開始
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

### 主要APIの説明

#### PassByManager（シングルトン）
- `getInstance()`: インスタンスを取得
- `startScanning(serviceUUID)`: BLEスキャニング開始
- `stopScanning()`: BLEスキャニング停止
- `isScanning()`: スキャニング中かどうか確認
- `setDeviceDiscoveredCallback()`: デバイス発見コールバックの設定
- `getDiscoveredDevices()`: 発見されたデバイスUUIDのリストを取得
- `clearDiscoveredDevices()`: 発見されたデバイスリストをクリア
- `getCurrentServiceUUID()`: 現在のサービスUUIDを取得（スキャニング中でない場合は空文字）
- `getVersion()`: ライブラリのバージョンを取得

#### 実装上の注意点
- PassByManagerはシングルトンなので、複数箇所から同一インスタンスを取得可能
- デバイス発見コールバックは別スレッドで実行されるため、UI更新時はメインスレッドにディスパッチ
- サービスUUIDは空文字列を渡すとすべてのデバイスをスキャン
- iOSでは Core Bluetooth フレームワークを使用（バックグラウンドモードが必要）

### Notes for Development
- Always run tests before committing changes: `./build_and_test.sh`
- iOS framework build: `./build_ios_framework.sh`
- Test builds are configured to run serially to avoid singleton conflicts
- Use `PASSBY_TESTING_ENABLED` define for test-only functionality