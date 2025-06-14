#include <gtest/gtest.h>
#include "PassBy/PassBy.h"

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

TEST_F(PassByManagerTest, DeviceDiscovery) {
    // Test device discovery callback
    std::vector<PassBy::DeviceInfo> discoveredDevices;
    manager->setDeviceDiscoveredCallback([&discoveredDevices](const PassBy::DeviceInfo& device) {
        discoveredDevices.push_back(device);
    });
    
    // Simulate device discovery
    manager->onDeviceDiscovered("test-uuid-1");
    manager->onDeviceDiscovered("test-uuid-2");
    
    // Check callback was called
    EXPECT_EQ(discoveredDevices.size(), 2);
    EXPECT_EQ(discoveredDevices[0].uuid, "test-uuid-1");
    EXPECT_EQ(discoveredDevices[1].uuid, "test-uuid-2");
}

TEST_F(PassByManagerTest, GetDiscoveredDevices) {
    // Initially no devices
    auto devices = manager->getDiscoveredDevices();
    EXPECT_TRUE(devices.empty());
    
    // Add some devices
    manager->onDeviceDiscovered("device-1");
    manager->onDeviceDiscovered("device-2");
    manager->onDeviceDiscovered("device-1"); // Duplicate should be ignored
    
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
    // Add devices
    manager->onDeviceDiscovered("device-1");
    manager->onDeviceDiscovered("device-2");
    
    auto devices = manager->getDiscoveredDevices();
    EXPECT_EQ(devices.size(), 2);
    
    // Clear devices
    manager->clearDiscoveredDevices();
    devices = manager->getDiscoveredDevices();
    EXPECT_TRUE(devices.empty());
}