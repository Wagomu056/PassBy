#include "PassBy/PassBy.h"
#include "../internal/PassByBridge.h"
#include "../internal/PlatformInterface.h"
#if TARGET_OS_IPHONE
#include "../ios/PassBy/PassByiOSPlatform.h"
#endif

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

PassByManager& PassByManager::getInstance(const std::string& serviceUUID) {
    std::lock_guard<std::mutex> lock(s_mutex);
    if (!s_instance) {
        // Use a temporary unique_ptr to ensure proper initialization
        auto temp = std::unique_ptr<PassByManager>(new PassByManager(serviceUUID));
        s_instance = std::move(temp);
    } else {
        // Update service UUID if instance already exists
        s_instance->m_serviceUUID = serviceUUID;
    }
    return *s_instance;
}

PassByManager::PassByManager() : m_isScanning(false), m_deviceCallback(nullptr), m_serviceUUID("") {
    initialize();
}

PassByManager::PassByManager(const std::string& serviceUUID) 
    : m_isScanning(false), m_deviceCallback(nullptr), m_serviceUUID(serviceUUID) {
    initialize();
}

void PassByManager::initialize() {
    // Create platform if not provided
    if (!m_platform) {
#if TARGET_OS_IPHONE
        m_platform = std::make_unique<iOSPlatform>();
#elif defined(ANDROID)
        // TODO: Add Android platform when implemented
        // m_platform = std::make_unique<AndroidPlatform>();
        m_platform = nullptr;
#else
        // For testing/development on macOS
        m_platform = nullptr;
#endif
    }
    
    // Automatically register this manager with the bridge
    PassByBridge::setManager(this);
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
        if (m_platform->startBLE(m_serviceUUID)) {
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