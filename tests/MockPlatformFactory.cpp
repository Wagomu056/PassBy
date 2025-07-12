#include "../src/internal/PlatformFactory.h"

namespace PassBy {

class MockPlatform : public PlatformInterface {
public:
    bool startBLE(const std::string& serviceUUID = "", const std::string& localName = "") override {
        return true;
    }
    
    bool stopBLE() override {
        return true;
    }
    
    bool isBLEActive() const override {
        return false;
    }
};

std::unique_ptr<PlatformInterface> PlatformFactory::createPlatform() {
    return std::make_unique<MockPlatform>();
}

} // namespace PassBy