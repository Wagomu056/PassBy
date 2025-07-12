#pragma once

#include <string>
#include <vector>
#include <functional>

namespace PassBy {

// Simple device information from BLE scan
struct DeviceInfo {
    std::string uuid;
    
    DeviceInfo(const std::string& deviceUuid) : uuid(deviceUuid) {}
};

// Advertising information for callback
struct AdvertisingInfo {
    std::string peripheralUUID;  // CBPeripheralManager.identifier.UUIDString
    bool success;
    std::string errorMessage;    // エラー時のメッセージ
    
    AdvertisingInfo(const std::string& uuid, bool isSuccess, const std::string& error = "")
        : peripheralUUID(uuid), success(isSuccess), errorMessage(error) {}
};

// Callback function types
using DeviceDiscoveredCallback = std::function<void(const DeviceInfo&)>;
using AdvertisingStartedCallback = std::function<void(const AdvertisingInfo&)>;

} // namespace PassBy