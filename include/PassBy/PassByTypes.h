#pragma once

#include <string>
#include <vector>
#include <functional>

namespace PassBy {

// Simple device information from BLE scan
struct DeviceInfo {
    std::string uuid;
    std::string deviceHash;  // Hash of device identifier from manufacturer data
    
    DeviceInfo(const std::string& deviceUuid) : uuid(deviceUuid) {}
    DeviceInfo(const std::string& deviceUuid, const std::string& hash) : uuid(deviceUuid), deviceHash(hash) {}
};

// Callback function types
using DeviceDiscoveredCallback = std::function<void(const DeviceInfo&)>;

} // namespace PassBy