#include <gtest/gtest.h>
#include "PassBy/PassBy.h"
#include "../src/internal/PassByBridge.h"

class PassByManagerTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Reset singleton for each test
        PassBy::PassByManager::_resetForTesting();
    }

    void TearDown() override {
        // Reset singleton after each test
        PassBy::PassByManager::_resetForTesting();
    }
};

TEST_F(PassByManagerTest, InitialState) {
    auto& manager = PassBy::PassByManager::getInstance();
    EXPECT_FALSE(manager.isScanning());
}

TEST_F(PassByManagerTest, StartScanning) {
    auto& manager = PassBy::PassByManager::getInstance();
    EXPECT_TRUE(manager.startScanning());
    EXPECT_TRUE(manager.isScanning());
    manager.stopScanning(); // cleanup
}

TEST_F(PassByManagerTest, StopScanning) {
    auto& manager = PassBy::PassByManager::getInstance();
    manager.startScanning();
    EXPECT_TRUE(manager.isScanning());
    
    EXPECT_TRUE(manager.stopScanning());
    EXPECT_FALSE(manager.isScanning());
}

TEST_F(PassByManagerTest, StartScanningTwice) {
    auto& manager = PassBy::PassByManager::getInstance();
    EXPECT_TRUE(manager.startScanning());
    EXPECT_FALSE(manager.startScanning()); // Should return false when already scanning
    EXPECT_TRUE(manager.isScanning());
    manager.stopScanning(); // cleanup
}

TEST_F(PassByManagerTest, StopScanningTwice) {
    auto& manager = PassBy::PassByManager::getInstance();
    manager.startScanning();
    EXPECT_TRUE(manager.stopScanning());
    EXPECT_FALSE(manager.stopScanning()); // Should return false when not scanning
    EXPECT_FALSE(manager.isScanning());
}

TEST_F(PassByManagerTest, GetVersion) {
    std::string version = PassBy::PassByManager::getVersion();
    EXPECT_FALSE(version.empty());
    EXPECT_EQ(version, "0.1.0");
}

TEST_F(PassByManagerTest, DeviceDiscoveryViaBridge) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    // Bridge should be automatically set up in constructor
    // Verify the manager is registered
    EXPECT_EQ(PassBy::PassByBridge::getManager(), &manager);
    
    // Clear any existing devices
    manager.clearDiscoveredDevices();
    
    // Test device discovery callback
    std::vector<PassBy::DeviceInfo> discoveredDevices;
    manager.setDeviceDiscoveredCallback([&discoveredDevices](const PassBy::DeviceInfo& device) {
        discoveredDevices.push_back(device);
    });
    
    // Simulate device discovery via bridge
    PassBy::PassByBridge::onDeviceDiscovered("test-uuid-1");
    PassBy::PassByBridge::onDeviceDiscovered("test-uuid-2");
    
    // Check callback was called
    EXPECT_EQ(discoveredDevices.size(), 2);
    EXPECT_EQ(discoveredDevices[0].uuid, "test-uuid-1");
    EXPECT_EQ(discoveredDevices[1].uuid, "test-uuid-2");
    
    // Cleanup
    manager.clearDiscoveredDevices();
}

TEST_F(PassByManagerTest, GetDiscoveredDevices) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    // Bridge should be automatically set up - verify it
    EXPECT_EQ(PassBy::PassByBridge::getManager(), &manager);
    
    // Clear any existing devices
    manager.clearDiscoveredDevices();
    
    // Initially no devices
    auto devices = manager.getDiscoveredDevices();
    EXPECT_TRUE(devices.empty());
    
    // Add some devices via bridge
    PassBy::PassByBridge::onDeviceDiscovered("device-1");
    PassBy::PassByBridge::onDeviceDiscovered("device-2");
    PassBy::PassByBridge::onDeviceDiscovered("device-1"); // Duplicate should be ignored
    
    devices = manager.getDiscoveredDevices();
    EXPECT_EQ(devices.size(), 2);
    
    // Check devices are present
    bool found1 = false, found2 = false;
    for (const auto& device : devices) {
        if (device == "device-1") found1 = true;
        if (device == "device-2") found2 = true;
    }
    EXPECT_TRUE(found1);
    EXPECT_TRUE(found2);
    
    // Cleanup
    manager.clearDiscoveredDevices();
}

TEST_F(PassByManagerTest, ClearDiscoveredDevices) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    // Bridge should be automatically set up - verify it
    EXPECT_EQ(PassBy::PassByBridge::getManager(), &manager);
    
    // Clear any existing devices first
    manager.clearDiscoveredDevices();
    
    // Add devices
    PassBy::PassByBridge::onDeviceDiscovered("device-1");
    PassBy::PassByBridge::onDeviceDiscovered("device-2");
    
    auto devices = manager.getDiscoveredDevices();
    EXPECT_EQ(devices.size(), 2);
    
    // Clear devices
    manager.clearDiscoveredDevices();
    devices = manager.getDiscoveredDevices();
    EXPECT_TRUE(devices.empty());
}

TEST_F(PassByManagerTest, AutomaticBridgeRegistration) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    // Test that bridge is automatically registered without manual setManager call
    EXPECT_EQ(PassBy::PassByBridge::getManager(), &manager);
    
    // Test with serviceUUID - should get same instance
    auto& managerWithUUID = PassBy::PassByManager::getInstance("test-service-uuid");
    EXPECT_EQ(&managerWithUUID, &manager);
    EXPECT_EQ(PassBy::PassByBridge::getManager(), &manager);
}

TEST_F(PassByManagerTest, SingletonBehavior) {
    // Test that getInstance always returns the same instance
    auto& manager1 = PassBy::PassByManager::getInstance();
    auto& manager2 = PassBy::PassByManager::getInstance();
    auto& manager3 = PassBy::PassByManager::getInstance("different-uuid");
    
    EXPECT_EQ(&manager1, &manager2);
    EXPECT_EQ(&manager2, &manager3);
    EXPECT_EQ(&manager1, &manager3);
}