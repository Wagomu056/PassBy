#include <gtest/gtest.h>
#include "PassBy/PassBy.h"
#include "../src/internal/PassByBridge.h"

class PassByManagerTest : public ::testing::Test {
protected:
    void SetUp() override {
        manager = std::make_unique<PassBy::PassByManager>();
    }

    void TearDown() override {
        manager.reset();
    }

    std::unique_ptr<PassBy::PassByManager> manager;
};

TEST_F(PassByManagerTest, InitialState) {
    EXPECT_FALSE(manager->isScanning());
}

TEST_F(PassByManagerTest, StartScanning) {
    EXPECT_TRUE(manager->startScanning());
    EXPECT_TRUE(manager->isScanning());
}

TEST_F(PassByManagerTest, StopScanning) {
    manager->startScanning();
    EXPECT_TRUE(manager->isScanning());
    
    EXPECT_TRUE(manager->stopScanning());
    EXPECT_FALSE(manager->isScanning());
}

TEST_F(PassByManagerTest, StartScanningTwice) {
    EXPECT_TRUE(manager->startScanning());
    EXPECT_FALSE(manager->startScanning()); // Should return false when already scanning
    EXPECT_TRUE(manager->isScanning());
}

TEST_F(PassByManagerTest, StopScanningTwice) {
    manager->startScanning();
    EXPECT_TRUE(manager->stopScanning());
    EXPECT_FALSE(manager->stopScanning()); // Should return false when not scanning
    EXPECT_FALSE(manager->isScanning());
}

TEST_F(PassByManagerTest, GetVersion) {
    std::string version = PassBy::PassByManager::getVersion();
    EXPECT_FALSE(version.empty());
    EXPECT_EQ(version, "0.1.0");
}

TEST_F(PassByManagerTest, DeviceDiscoveryViaBridge) {
    // Bridge should be automatically set up in constructor
    // Verify the manager is registered
    EXPECT_EQ(PassBy::PassByBridge::getManager(), manager.get());
    
    // Test device discovery callback
    std::vector<PassBy::DeviceInfo> discoveredDevices;
    manager->setDeviceDiscoveredCallback([&discoveredDevices](const PassBy::DeviceInfo& device) {
        discoveredDevices.push_back(device);
    });
    
    // Simulate device discovery via bridge
    PassBy::PassByBridge::onDeviceDiscovered("test-uuid-1");
    PassBy::PassByBridge::onDeviceDiscovered("test-uuid-2");
    
    // Check callback was called
    EXPECT_EQ(discoveredDevices.size(), 2);
    EXPECT_EQ(discoveredDevices[0].uuid, "test-uuid-1");
    EXPECT_EQ(discoveredDevices[1].uuid, "test-uuid-2");
}

TEST_F(PassByManagerTest, GetDiscoveredDevices) {
    // Bridge should be automatically set up - verify it
    EXPECT_EQ(PassBy::PassByBridge::getManager(), manager.get());
    
    // Initially no devices
    auto devices = manager->getDiscoveredDevices();
    EXPECT_TRUE(devices.empty());
    
    // Add some devices via bridge
    PassBy::PassByBridge::onDeviceDiscovered("device-1");
    PassBy::PassByBridge::onDeviceDiscovered("device-2");
    PassBy::PassByBridge::onDeviceDiscovered("device-1"); // Duplicate should be ignored
    
    devices = manager->getDiscoveredDevices();
    EXPECT_EQ(devices.size(), 2);
    
    // Check devices are present
    bool found1 = false, found2 = false;
    for (const auto& device : devices) {
        if (device == "device-1") found1 = true;
        if (device == "device-2") found2 = true;
    }
    EXPECT_TRUE(found1);
    EXPECT_TRUE(found2);
}

TEST_F(PassByManagerTest, ClearDiscoveredDevices) {
    // Bridge should be automatically set up - verify it
    EXPECT_EQ(PassBy::PassByBridge::getManager(), manager.get());
    
    // Add devices
    PassBy::PassByBridge::onDeviceDiscovered("device-1");
    PassBy::PassByBridge::onDeviceDiscovered("device-2");
    
    auto devices = manager->getDiscoveredDevices();
    EXPECT_EQ(devices.size(), 2);
    
    // Clear devices
    manager->clearDiscoveredDevices();
    devices = manager->getDiscoveredDevices();
    EXPECT_TRUE(devices.empty());
}

TEST_F(PassByManagerTest, AutomaticBridgeRegistration) {
    // Test that bridge is automatically registered without manual setManager call
    EXPECT_EQ(PassBy::PassByBridge::getManager(), manager.get());
    
    // Test with serviceUUID constructor
    auto managerWithUUID = std::make_unique<PassBy::PassByManager>("test-service-uuid");
    EXPECT_EQ(PassBy::PassByBridge::getManager(), managerWithUUID.get());
    
    // Test that newer manager overrides the bridge registration
    auto anotherManager = std::make_unique<PassBy::PassByManager>();
    EXPECT_EQ(PassBy::PassByBridge::getManager(), anotherManager.get());
    EXPECT_NE(PassBy::PassByBridge::getManager(), manager.get());
    EXPECT_NE(PassBy::PassByBridge::getManager(), managerWithUUID.get());
}