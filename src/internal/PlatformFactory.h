#pragma once

#include "PlatformInterface.h"
#include <memory>

namespace PassBy {

class PlatformFactory {
public:
    static std::unique_ptr<PlatformInterface> createPlatform();
};

} // namespace PassBy