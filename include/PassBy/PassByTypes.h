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

// Callback function types
using DeviceDiscoveredCallback = std::function<void(const DeviceInfo&)>;

} // namespace PassBy