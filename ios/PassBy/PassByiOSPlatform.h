#pragma once

#include "../../src/internal/PlatformInterface.h"

// Forward declare Objective-C class to avoid header dependencies
#ifdef __OBJC__
@class PassByBLEManager;
#else
typedef struct objc_object PassByBLEManager;
#endif

namespace PassBy {

// iOS implementation of PlatformInterface
class iOSPlatform : public PlatformInterface {
public:
    iOSPlatform();
    ~iOSPlatform() override;
    
    bool startBLE(const std::string& serviceUUID = "", const std::string& localName = "") override;
    bool stopBLE() override;
    bool isBLEActive() const override;

private:
    PassByBLEManager* m_bleManager;
};

} // namespace PassBy