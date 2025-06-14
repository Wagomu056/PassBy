#pragma once

#include <string>
#include <vector>
#include <set>
#include <memory>
#include "PassByTypes.h"
#include "PlatformInterface.h"

namespace PassBy {

class PassByManager {
public:
    PassByManager();
    explicit PassByManager(std::unique_ptr<PlatformInterface> platform);
    ~PassByManager();
    
    // Start BLE scanning
    bool startScanning();
    
    // Stop BLE scanning  
    bool stopScanning();
    
    // Check if currently scanning
    bool isScanning() const;
    
    // Set callback for device discovery
    void setDeviceDiscoveredCallback(DeviceDiscoveredCallback callback);
    
    // Get discovered devices
    std::vector<std::string> getDiscoveredDevices() const;
    
    // Clear discovered devices
    void clearDiscoveredDevices();
    
    // Get library version
    static std::string getVersion();

    // Called by platform-specific code when device is discovered
    void onDeviceDiscovered(const std::string& uuid);

private:
    bool m_isScanning;
    std::set<std::string> m_discoveredDevices;
    DeviceDiscoveredCallback m_deviceCallback;
    std::unique_ptr<PlatformInterface> m_platform;
};

} // namespace PassBy