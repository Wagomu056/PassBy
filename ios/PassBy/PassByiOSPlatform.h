#pragma once

#include "PassBy/PlatformInterface.h"

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
    
    bool startBLE() override;
    bool stopBLE() override;
    bool isBLEActive() const override;

private:
    PassByBLEManager* m_bleManager;
};

} // namespace PassBy