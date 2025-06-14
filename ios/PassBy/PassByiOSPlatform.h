#pragma once

#include "PassBy/PlatformInterface.h"

@class PassByBLEManager;

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