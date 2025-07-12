#pragma once

#include <string>

namespace PassBy {

class PassByManager;

// Bridge class for platform-specific code to communicate with PassByManager
class PassByBridge {
public:
    // Set the manager instance to receive callbacks
    static void setManager(PassByManager* manager);
    
    // Called by platform-specific code when device is discovered
    static void onDeviceDiscovered(const std::string& uuid);
    
    // Called by platform-specific code when advertising is started
    static void onAdvertisingStarted(const std::string& peripheralUUID, bool success, const std::string& errorMessage = "");
    
    // Get current manager (for testing purposes)
    static PassByManager* getManager();

private:
    static PassByManager* s_manager;
};

} // namespace PassBy