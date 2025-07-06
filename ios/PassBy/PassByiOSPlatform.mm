#include "PassByiOSPlatform.h"
#import "PassByBLEManager.h"

namespace PassBy {

iOSPlatform::iOSPlatform() {
    m_bleManager = [[PassByBLEManager alloc] init];
}

iOSPlatform::~iOSPlatform() {
    if (m_bleManager) {
        [m_bleManager stopBLE];
        m_bleManager = nil;
    }
}

bool iOSPlatform::startBLE(const std::string& serviceUUID, const std::string& deviceIdentifier) {
    if (!m_bleManager) {
        return false;
    }
    
    // deviceIdentifier must be non-empty, serviceUUID can be empty (for scanning all devices)
    if (deviceIdentifier.empty()) {
        NSLog(@"Error: deviceIdentifier cannot be empty");
        return false;
    }
    
    NSString* nsServiceUUID = serviceUUID.empty() ? nil : [NSString stringWithUTF8String:serviceUUID.c_str()];
    NSString* nsDeviceIdentifier = [NSString stringWithUTF8String:deviceIdentifier.c_str()];
    NSLog(@"Starting BLE with service UUID: %@, device identifier: %@", nsServiceUUID, nsDeviceIdentifier);
    return [m_bleManager startBLEWithServiceUUID:nsServiceUUID deviceIdentifier:nsDeviceIdentifier];
}

bool iOSPlatform::stopBLE() {
    if (!m_bleManager) {
        return false;
    }
    return [m_bleManager stopBLE];
}

bool iOSPlatform::isBLEActive() const {
    if (!m_bleManager) {
        return false;
    }
    return m_bleManager.isActive;
}

} // namespace PassBy