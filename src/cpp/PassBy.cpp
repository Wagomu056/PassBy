#include "PassBy/PassBy.h"
#include "../internal/PassByBridge.h"
#include "../internal/PlatformInterface.h"
#include "../internal/PlatformFactory.h"

namespace PassBy {

// Static member definitions
std::unique_ptr<PassByManager> PassByManager::s_instance = nullptr;
std::mutex PassByManager::s_mutex;

PassByManager& PassByManager::getInstance() {
    std::lock_guard<std::mutex> lock(s_mutex);
    if (!s_instance) {
        // Use a temporary unique_ptr to ensure proper initialization
        auto temp = std::unique_ptr<PassByManager>(new PassByManager());
        s_instance = std::move(temp);
    }
    return *s_instance;
}


PassByManager::PassByManager() : m_isScanning(false), m_deviceCallback(nullptr), m_currentServiceUUID("") {
    // Create platform using factory
    m_platform = PlatformFactory::createPlatform();
    
    // Automatically register this manager with the bridge
    PassByBridge::setManager(this);
}

PassByManager::~PassByManager() {
    if (m_isScanning) {
        stopScanning();
    }
}

bool PassByManager::startScanning(const std::string& serviceUUID, const std::string& localName) {
    if (m_isScanning) {
        return false;
    }
    
    // Store the service UUID for this scanning session
    m_currentServiceUUID = serviceUUID;
    
    // Use platform interface if available
    if (m_platform) {
        if (m_platform->startBLE(serviceUUID, localName)) {
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
            m_currentServiceUUID.clear(); // Clear service UUID when stopping
            return true;
        }
        return false;
    }
    
    // Default behavior for testing
    m_isScanning = false;
    m_currentServiceUUID.clear(); // Clear service UUID when stopping
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

const std::string& PassByManager::getCurrentServiceUUID() const {
    return m_currentServiceUUID;
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