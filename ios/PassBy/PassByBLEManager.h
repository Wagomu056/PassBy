#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface PassByBLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, readonly) BOOL isActive;

- (BOOL)startBLEWithServiceUUID:(nullable NSString*)serviceUUID;
- (BOOL)stopBLE;

@end

NS_ASSUME_NONNULL_END