#include <gtest/gtest.h>
#include "PassBy/PassBy.h"
#include "../src/internal/PassByBridge.h"
#include "TestPassByManager.h"

class PassByManagerTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Reset singleton for each test
        PassBy::TestPassByManager::resetForTesting();
    }

    void TearDown() override {
        // Reset singleton after each test
        PassBy::TestPassByManager::resetForTesting();
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

TEST_F(PassByManagerTest, SingletonBehavior) {
    // Test that getInstance always returns the same instance
    auto& manager1 = PassBy::PassByManager::getInstance();
    auto& manager2 = PassBy::PassByManager::getInstance();
    
    EXPECT_EQ(&manager1, &manager2);
}

TEST_F(PassByManagerTest, ServiceUUIDHandling) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    // Initially no service UUID
    EXPECT_TRUE(manager.getCurrentServiceUUID().empty());
    
    // Start scanning with service UUID
    EXPECT_TRUE(manager.startScanning("test-service-uuid"));
    EXPECT_EQ(manager.getCurrentServiceUUID(), "test-service-uuid");
    EXPECT_TRUE(manager.isScanning());
    
    // Stop scanning should clear service UUID
    EXPECT_TRUE(manager.stopScanning());
    EXPECT_TRUE(manager.getCurrentServiceUUID().empty());
    EXPECT_FALSE(manager.isScanning());
}

TEST_F(PassByManagerTest, ScanningWithoutServiceUUID) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    // Start scanning without service UUID (empty string)
    EXPECT_TRUE(manager.startScanning());
    EXPECT_TRUE(manager.getCurrentServiceUUID().empty());
    EXPECT_TRUE(manager.isScanning());
    
    // Stop scanning
    EXPECT_TRUE(manager.stopScanning());
    EXPECT_FALSE(manager.isScanning());
}

TEST_F(PassByManagerTest, ServiceUUIDChangeBetweenScans) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    // First scan with UUID1
    EXPECT_TRUE(manager.startScanning("uuid-1"));
    EXPECT_EQ(manager.getCurrentServiceUUID(), "uuid-1");
    
    // Stop scanning
    EXPECT_TRUE(manager.stopScanning());
    EXPECT_TRUE(manager.getCurrentServiceUUID().empty());
    
    // Start new scan with UUID2
    EXPECT_TRUE(manager.startScanning("uuid-2"));
    EXPECT_EQ(manager.getCurrentServiceUUID(), "uuid-2");
    
    // Cleanup
    manager.stopScanning();
}

TEST_F(PassByManagerTest, AdvertisingStartedSuccess) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    PassBy::AdvertisingInfo receivedInfo("", false);
    bool callbackCalled = false;
    
    manager.setAdvertisingStartedCallback([&](const PassBy::AdvertisingInfo& info) {
        receivedInfo = info;
        callbackCalled = true;
    });
    
    manager.startScanning();
    // 成功ケースをシミュレート
    manager.onAdvertisingStarted("uuid-success-123", true);
    
    EXPECT_TRUE(callbackCalled);
    EXPECT_TRUE(receivedInfo.success);
    EXPECT_EQ(receivedInfo.peripheralUUID, "uuid-success-123");
    EXPECT_TRUE(receivedInfo.errorMessage.empty());
}

TEST_F(PassByManagerTest, AdvertisingStartedFailure) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    PassBy::AdvertisingInfo receivedInfo("", true);
    bool callbackCalled = false;
    
    manager.setAdvertisingStartedCallback([&](const PassBy::AdvertisingInfo& info) {
        receivedInfo = info;
        callbackCalled = true;
    });
    
    manager.startScanning();
    // 失敗ケースをシミュレート
    manager.onAdvertisingStarted("", false, "Bluetooth not available");
    
    EXPECT_TRUE(callbackCalled);
    EXPECT_FALSE(receivedInfo.success);
    EXPECT_TRUE(receivedInfo.peripheralUUID.empty());
    EXPECT_EQ(receivedInfo.errorMessage, "Bluetooth not available");
}

TEST_F(PassByManagerTest, AdvertisingStartedWithoutCallback) {
    auto& manager = PassBy::PassByManager::getInstance();
    
    manager.startScanning();
    // コールバック未設定でonAdvertisingStartedを呼んでもクラッシュしないことを確認
    EXPECT_NO_THROW(manager.onAdvertisingStarted("uuid-test", true));
    EXPECT_NO_THROW(manager.onAdvertisingStarted("", false, "Error"));
}