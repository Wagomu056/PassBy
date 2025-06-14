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

bool iOSPlatform::startBLE() {
    if (!m_bleManager) {
        return false;
    }
    return [m_bleManager startBLE];
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