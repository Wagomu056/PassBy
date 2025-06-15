#pragma once

#include <string>
#include <vector>
#include <set>
#include <memory>
#include <mutex>
#include "PassByTypes.h"

namespace PassBy {

// Forward declarations
class PlatformInterface;

class PassByManager {
public:
    // Singleton access
    static PassByManager& getInstance();
    static PassByManager& getInstance(const std::string& serviceUUID);
    
    // No public constructors
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

#ifdef PASSBY_TESTING_ENABLED
    // For testing only - reset singleton state
    static void _resetForTesting();
#endif

private:
    // Private constructors for singleton
    PassByManager();
    explicit PassByManager(const std::string& serviceUUID);
    
    // Copy and move operations deleted
    PassByManager(const PassByManager&) = delete;
    PassByManager& operator=(const PassByManager&) = delete;
    PassByManager(PassByManager&&) = delete;
    PassByManager& operator=(PassByManager&&) = delete;
    
    void initialize();
    
    // Singleton instance
    static std::unique_ptr<PassByManager> s_instance;
    static std::mutex s_mutex;
    
    // Instance data
    bool m_isScanning;
    std::set<std::string> m_discoveredDevices;
    DeviceDiscoveredCallback m_deviceCallback;
    std::unique_ptr<PlatformInterface> m_platform;
    std::string m_serviceUUID;
};

} // namespace PassBy