#include "../internal/PassByBridge.h"
#include "PassBy/PassBy.h"

namespace PassBy {

PassByManager* PassByBridge::s_manager = nullptr;

void PassByBridge::setManager(PassByManager* manager) {
    s_manager = manager;
}

void PassByBridge::onDeviceDiscovered(const std::string& uuid) {
    if (s_manager) {
        s_manager->onDeviceDiscovered(uuid);
    }
}

void PassByBridge::onAdvertisingStarted(const std::string& peripheralUUID, bool success, const std::string& errorMessage) {
    if (s_manager) {
        s_manager->onAdvertisingStarted(peripheralUUID, success, errorMessage);
    }
}

PassByManager* PassByBridge::getManager() {
    return s_manager;
}

} // namespace PassBy