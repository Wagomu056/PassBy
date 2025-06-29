#include "../../internal/PlatformFactory.h"
#include "../../../ios/PassBy/PassByiOSPlatform.h"

namespace PassBy {

std::unique_ptr<PlatformInterface> PlatformFactory::createPlatform() {
    return std::make_unique<iOSPlatform>();
}

} // namespace PassBy