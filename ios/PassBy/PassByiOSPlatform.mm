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

bool iOSPlatform::startBLE(const std::string& serviceUUID, const std::string& localName) {
    if (!m_bleManager) {
        return false;
    }
    
    NSString* nsServiceUUID = serviceUUID.empty() ? nil : [NSString stringWithUTF8String:serviceUUID.c_str()];
    NSString* nsLocalName = localName.empty() ? nil : [NSString stringWithUTF8String:localName.c_str()];
    NSLog(@"Starting BLE with service UUID: %@, local name: %@", nsServiceUUID, nsLocalName);
    return [m_bleManager startBLEWithServiceUUID:nsServiceUUID localName:nsLocalName];
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