#pragma once

namespace PassBy {

// Abstract interface for platform-specific BLE operations
class PlatformInterface {
public:
    virtual ~PlatformInterface() = default;
    
    // Start BLE scanning and advertising
    virtual bool startBLE() = 0;
    
    // Stop BLE scanning and advertising
    virtual bool stopBLE() = 0;
    
    // Check if BLE is active
    virtual bool isBLEActive() const = 0;
};

} // namespace PassBy