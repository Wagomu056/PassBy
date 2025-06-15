#pragma once

#include <string>
#include <vector>
#include <set>
#include <memory>
#include "PassByTypes.h"

namespace PassBy {

// Forward declarations
class PlatformInterface;

class PassByManager {
public:
    PassByManager();
    explicit PassByManager(const std::string& serviceUUID);
    explicit PassByManager(std::unique_ptr<PlatformInterface> platform);
    PassByManager(std::unique_ptr<PlatformInterface> platform, const std::string& serviceUUID);
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
    void initialize();
    
    bool m_isScanning;
    std::set<std::string> m_discoveredDevices;
    DeviceDiscoveredCallback m_deviceCallback;
    std::unique_ptr<PlatformInterface> m_platform;
    std::string m_serviceUUID;
};

} // namespace PassBy