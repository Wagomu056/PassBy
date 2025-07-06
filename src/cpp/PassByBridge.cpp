#include "../internal/PassByBridge.h"
#include "PassBy/PassBy.h"

namespace PassBy {

PassByManager* PassByBridge::s_manager = nullptr;

void PassByBridge::setManager(PassByManager* manager) {
    s_manager = manager;
}

void PassByBridge::onDeviceDiscovered(const std::string& uuid, const std::string& deviceHash) {
    if (s_manager) {
        s_manager->onDeviceDiscovered(uuid, deviceHash);
    }
}

PassByManager* PassByBridge::getManager() {
    return s_manager;
}

} // namespace PassBy