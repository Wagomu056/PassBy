#pragma once

#include <string>
#include <vector>
#include <set>
#include <memory>
#include <mutex>
#include <PassBy/PassByTypes.h>

namespace PassBy {

// Forward declarations
class PlatformInterface;

class PassByManager {
public:
    // Singleton access
    static PassByManager& getInstance();
    
    // No public constructors
    ~PassByManager();
    
    // Start BLE scanning with optional service UUID filter and device identifier
    bool startScanning(const std::string& serviceUUID = "", const std::string& deviceIdentifier = "");
    
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
    
    // Get current service UUID (empty if not scanning or no filter)
    const std::string& getCurrentServiceUUID() const;
    
    // Get library version
    static std::string getVersion();

    // Called by platform-specific code when device is discovered
    void onDeviceDiscovered(const std::string& uuid);
    
    // Called by platform-specific code when device is discovered with hash
    void onDeviceDiscoveredWithHash(const std::string& uuid, const std::string& deviceHash);

#ifdef PASSBY_TESTING_ENABLED
protected:  // テストビルド時のみprotected
#else
private:    // 通常ビルドではprivate
#endif
    // Private constructor for singleton
    PassByManager();
    
    // Copy and move operations deleted
    PassByManager(const PassByManager&) = delete;
    PassByManager& operator=(const PassByManager&) = delete;
    PassByManager(PassByManager&&) = delete;
    PassByManager& operator=(PassByManager&&) = delete;
    
    // Singleton instance
    static std::unique_ptr<PassByManager> s_instance;
    static std::mutex s_mutex;
    
    // Instance data
    bool m_isScanning;
    std::set<std::string> m_discoveredDevices;
    DeviceDiscoveredCallback m_deviceCallback;
    std::unique_ptr<PlatformInterface> m_platform;
    std::string m_currentServiceUUID;
};

} // namespace PassBy