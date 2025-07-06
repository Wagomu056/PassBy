#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface PassByBLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralManagerDelegate>

@property (nonatomic, readonly) BOOL isActive;

- (BOOL)startBLEWithServiceUUID:(NSString*)serviceUUID deviceIdentifier:(NSString*)deviceIdentifier;
- (BOOL)stopBLE;

@end

NS_ASSUME_NONNULL_END