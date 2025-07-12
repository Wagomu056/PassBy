#import "PassByBLEManager.h"
#include "../../src/internal/PassByBridge.h"

// UUID for PassBy service and characteristic
static NSString * const kPassByServiceUUID = @"12345678-1234-1234-1234-123456789ABC";
static NSString * const kPassByCharacteristicUUID = @"87654321-4321-4321-4321-CBA987654321";

@interface PassByBLEManager ()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *passByService;
@property (nonatomic, strong) CBMutableCharacteristic *passByCharacteristic;
@property (nonatomic, assign) BOOL isScanning;
@property (nonatomic, assign) BOOL isAdvertising;
@property (nonatomic, strong) NSString *pendingServiceUUID;
@property (nonatomic, strong) NSString *pendingLocalName;

@end

@implementation PassByBLEManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        _isScanning = NO;
        _isAdvertising = NO;
    }
    return self;
}

- (BOOL)isActive {
    return _isScanning || _isAdvertising;
}

- (BOOL)startBLEWithServiceUUID:(nullable NSString*)serviceUUID localName:(nullable NSString*)localName {
    if (self.isActive) {
        return NO;
    }
    
    [self startScanningWithServiceUUID:serviceUUID];
    [self startAdvertisingWithLocalName:localName];
    
    return YES;
}

- (BOOL)stopBLE {
    if (!self.isActive) {
        return NO;
    }
    
    [self stopScanning];
    [self stopAdvertising];
    
    return YES;
}

#pragma mark - Private Methods

- (void)startScanningWithServiceUUID:(nullable NSString*)serviceUUID {
    if (!_isScanning) {
        _isScanning = YES;
        self.pendingServiceUUID = serviceUUID;
        
        if (_centralManager.state == CBManagerStatePoweredOn) {
            [self actuallyStartScanning];
        } else {
            NSLog(@"Central Manager not ready (state: %ld), will start when powered on", (long)_centralManager.state);
        }
    }
}

- (void)actuallyStartScanning {
    NSArray<CBUUID*>* services = nil;
    if (self.pendingServiceUUID && self.pendingServiceUUID.length > 0) {
        CBUUID *uuid = [CBUUID UUIDWithString:self.pendingServiceUUID];
        services = @[uuid];
        NSLog(@"Started BLE scanning for service: %@", self.pendingServiceUUID);
    } else {
        NSLog(@"Started BLE scanning for all devices");
    }
    
    [_centralManager scanForPeripheralsWithServices:services options:nil];
}

- (void)stopScanning {
    if (_isScanning) {
        [_centralManager stopScan];
        _isScanning = NO;
        NSLog(@"Stopped BLE scanning");
    }
}

- (void)startAdvertising {
    [self startAdvertisingWithLocalName:nil];
}

- (void)startAdvertisingWithLocalName:(nullable NSString*)localName {
    if (_peripheralManager.state == CBManagerStatePoweredOn && !_isAdvertising) {
        self.pendingLocalName = localName;
        
        // Setup service and characteristic
        [self setupPeripheralService];
        
        // Use provided localName or default to "PassBy"
        NSString *advertisingName = localName && localName.length > 0 ? localName : @"PassBy";
        
        // Start advertising
        NSDictionary *advertisingData = @{
            CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:kPassByServiceUUID]],
            CBAdvertisementDataLocalNameKey: advertisingName
        };
        
        [_peripheralManager startAdvertising:advertisingData];
        _isAdvertising = YES;
        NSLog(@"Started BLE advertising with local name: %@", advertisingName);
    } else if (_peripheralManager.state != CBManagerStatePoweredOn) {
        self.pendingLocalName = localName;
        NSLog(@"Peripheral Manager not ready (state: %ld), will start advertising when powered on", (long)_peripheralManager.state);
    }
}

- (void)stopAdvertising {
    if (_isAdvertising) {
        [_peripheralManager stopAdvertising];
        _isAdvertising = NO;
        NSLog(@"Stopped BLE advertising");
    }
}

- (void)setupPeripheralService {
    // Create characteristic
    _passByCharacteristic = [[CBMutableCharacteristic alloc]
                           initWithType:[CBUUID UUIDWithString:kPassByCharacteristicUUID]
                           properties:CBCharacteristicPropertyRead
                           value:nil
                           permissions:CBAttributePermissionsReadable];
    
    // Create service
    _passByService = [[CBMutableService alloc]
                     initWithType:[CBUUID UUIDWithString:kPassByServiceUUID]
                     primary:YES];
    
    _passByService.characteristics = @[_passByCharacteristic];
    
    // Add service to peripheral manager
    [_peripheralManager addService:_passByService];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"Central Manager state changed to: %ld", (long)central.state);
    switch (central.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"Central Manager powered on");
            if (_isScanning) {
                NSLog(@"Starting pending scan...");
                [self actuallyStartScanning];
            }
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Central Manager powered off");
            _isScanning = NO;
            break;
        default:
            NSLog(@"Central Manager in other state: %ld", (long)central.state);
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    // Generate a simple UUID for the discovered device
    NSString *deviceUUID = peripheral.identifier.UUIDString;
    NSString *deviceName = peripheral.name ?: @"Unknown";
    NSString *localName = advertisementData[CBAdvertisementDataLocalNameKey] ?: @"Unknown";
    
    NSLog(@"Discovered device: %@ (Name: %@, RSSI: %@, Local Name: %@)",
          deviceUUID, deviceName, RSSI, localName);
    
    // Report to C++ layer via bridge
    PassBy::PassByBridge::onDeviceDiscovered([localName UTF8String]);
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"Peripheral Manager powered on");
            if (_isAdvertising) {
                [self startAdvertisingWithLocalName:self.pendingLocalName];
            }
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Peripheral Manager powered off");
            _isAdvertising = NO;
            break;
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error adding service: %@", error.localizedDescription);
    } else {
        NSLog(@"Service added successfully");
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"Error starting advertising: %@", error.localizedDescription);
        _isAdvertising = NO;
    } else {
        NSLog(@"Started advertising successfully");
    }
}

@end