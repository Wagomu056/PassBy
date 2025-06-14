#include "PassBy/PassBy.h"

namespace PassBy {

PassByManager::PassByManager() : m_isScanning(false), m_deviceCallback(nullptr), m_platform(nullptr) {
}

PassByManager::PassByManager(std::unique_ptr<PlatformInterface> platform) 
    : m_isScanning(false), m_deviceCallback(nullptr), m_platform(std::move(platform)) {
}

PassByManager::~PassByManager() {
    if (m_isScanning) {
        stopScanning();
    }
}

bool PassByManager::startScanning() {
    if (m_isScanning) {
        return false;
    }
    
    // Use platform interface if available
    if (m_platform) {
        if (m_platform->startBLE()) {
            m_isScanning = true;
            return true;
        }
        return false;
    }
    
    // Default behavior for testing
    m_isScanning = true;
    return true;
}

bool PassByManager::stopScanning() {
    if (!m_isScanning) {
        return false;
    }
    
    // Use platform interface if available
    if (m_platform) {
        if (m_platform->stopBLE()) {
            m_isScanning = false;
            return true;
        }
        return false;
    }
    
    // Default behavior for testing
    m_isScanning = false;
    return true;
}

bool PassByManager::isScanning() const {
    return m_isScanning;
}

void PassByManager::setDeviceDiscoveredCallback(DeviceDiscoveredCallback callback) {
    m_deviceCallback = callback;
}

std::vector<std::string> PassByManager::getDiscoveredDevices() const {
    return std::vector<std::string>(m_discoveredDevices.begin(), m_discoveredDevices.end());
}

void PassByManager::clearDiscoveredDevices() {
    m_discoveredDevices.clear();
}

void PassByManager::onDeviceDiscovered(const std::string& uuid) {
    // Store device in memory
    m_discoveredDevices.insert(uuid);
    
    // Call user callback if set
    if (m_deviceCallback) {
        DeviceInfo device(uuid);
        m_deviceCallback(device);
    }
}

std::string PassByManager::getVersion() {
    return "0.1.0";
}

} // namespace PassBy