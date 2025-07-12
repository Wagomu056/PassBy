#import "PassByBLEManager.h"
#include "../../src/internal/PassByBridge.h"

// UUID for PassBy service and characteristics
static NSString * const kPassByServiceUUID = @"12345678-1234-1234-1234-123456789ABC";
static NSString * const kPassByCharacteristicUUID = @"87654321-4321-4321-4321-CBA987654321";
static NSString * const kPassByDeviceIdentifierUUID = @"11111111-2222-3333-4444-555555555555";

@interface PassByBLEManager ()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *passByService;
@property (nonatomic, strong) CBMutableCharacteristic *passByCharacteristic;
@property (nonatomic, strong) CBMutableCharacteristic *deviceIdentifierCharacteristic;
@property (nonatomic, assign) BOOL isScanning;
@property (nonatomic, assign) BOOL isAdvertising;
@property (nonatomic, strong) NSString *pendingServiceUUID;
// Custom property implemented manually
@property (nonatomic, strong) NSMutableSet<CBPeripheral*> *connectingPeripherals;

@end

@implementation PassByBLEManager {
    NSString *_internalDeviceIdentifier;
}

// Custom setter for validation
- (void)setDeviceIdentifier:(NSString *)deviceIdentifier {
    if ([deviceIdentifier isKindOfClass:[NSString class]]) {
        _internalDeviceIdentifier = [deviceIdentifier copy];
        NSLog(@"Device identifier set to: %@ (type: %@)", _internalDeviceIdentifier, [_internalDeviceIdentifier class]);
    } else {
        NSLog(@"ERROR: Attempted to set deviceIdentifier to non-string object: %@ (type: %@)", deviceIdentifier, [deviceIdentifier class]);
        _internalDeviceIdentifier = [[NSUUID UUID] UUIDString];
        NSLog(@"Created fallback identifier: %@", _internalDeviceIdentifier);
    }
}

- (NSString *)deviceIdentifier {
    if (![_internalDeviceIdentifier isKindOfClass:[NSString class]]) {
        NSLog(@"ERROR: Internal device identifier corrupted (type: %@), creating new one", [_internalDeviceIdentifier class]);
        _internalDeviceIdentifier = [[NSUUID UUID] UUIDString];
    }
    return _internalDeviceIdentifier;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        _isScanning = NO;
        _isAdvertising = NO;
        
        // Generate fixed device identifier for this app session
        NSString *newUUID = [[NSUUID UUID] UUIDString];
        self.deviceIdentifier = newUUID;  // Use setter for validation
        _connectingPeripherals = [[NSMutableSet alloc] init];
        
        NSLog(@"PassByBLEManager initialized with device identifier: %@ (type: %@)", self.deviceIdentifier, [self.deviceIdentifier class]);
    }
    return self;
}

- (BOOL)isActive {
    return _isScanning || _isAdvertising;
}

- (BOOL)startBLEWithServiceUUID:(nullable NSString*)serviceUUID {
    if (self.isActive) {
        return NO;
    }
    
    [self startScanningWithServiceUUID:serviceUUID];
    [self startAdvertising];
    
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
    if (_peripheralManager.state == CBManagerStatePoweredOn && !_isAdvertising) {
        // Setup service and characteristic
        [self setupPeripheralService];
        
        // Start advertising
        NSDictionary *advertisingData = @{
            CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:kPassByServiceUUID]],
            CBAdvertisementDataLocalNameKey: @"PassBy"
        };
        
        [_peripheralManager startAdvertising:advertisingData];
        _isAdvertising = YES;
        NSLog(@"Started BLE advertising");
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
    // Create original PassBy characteristic
    _passByCharacteristic = [[CBMutableCharacteristic alloc]
                           initWithType:[CBUUID UUIDWithString:kPassByCharacteristicUUID]
                           properties:CBCharacteristicPropertyRead
                           value:nil
                           permissions:CBAttributePermissionsReadable];
    
    // Create device identifier characteristic using getter for validation
    NSLog(@"setupPeripheralService called");
    NSString *identifierString = self.deviceIdentifier;  // Use getter for validation
    NSLog(@"Using device identifier: %@", identifierString);
    
    NSData *identifierData = [identifierString dataUsingEncoding:NSUTF8StringEncoding];
    _deviceIdentifierCharacteristic = [[CBMutableCharacteristic alloc]
                                     initWithType:[CBUUID UUIDWithString:kPassByDeviceIdentifierUUID]
                                     properties:CBCharacteristicPropertyRead
                                     value:identifierData
                                     permissions:CBAttributePermissionsReadable];
    
    // Create service with both characteristics
    _passByService = [[CBMutableService alloc]
                     initWithType:[CBUUID UUIDWithString:kPassByServiceUUID]
                     primary:YES];
    
    _passByService.characteristics = @[_passByCharacteristic, _deviceIdentifierCharacteristic];
    
    // Add service to peripheral manager
    [_peripheralManager addService:_passByService];
}

/*
 * BLE Discovery Flow: From Peripheral Discovery to Characteristic UUID Retrieval
 * 
 * The following sequence outlines the complete flow from discovering a peripheral
 * to obtaining its characteristic UUID values:
 * 
 * 1. didDiscoverPeripheral - Peripheral device is discovered during scanning
 * 2. connectPeripheral - Initiate connection to the discovered peripheral
 * 3. didConnectPeripheral - Connection established successfully
 * 4. discoverServices - Begin service discovery on the connected peripheral
 * 5. didDiscoverServices - Services are discovered and enumerated
 * 6. discoverCharacteristics - Start characteristic discovery for found services
 * 7. didDiscoverCharacteristicsForService - Characteristics are discovered
 * 8. readValueForCharacteristic - Initiate reading of characteristic values
 * 9. didUpdateValueForCharacteristic - Characteristic value read completed
 * 10. onDeviceDiscovered - Results reported to C++ layer via PassByBridge
 * 
 * This flow ensures proper BLE communication protocol adherence and retrieves
 * the device identifier from the kPassByDeviceIdentifierUUID characteristic.
 */

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
    
    NSString *deviceUUID = peripheral.identifier.UUIDString;
    NSString *deviceName = peripheral.name ?: @"Unknown";
    
    NSLog(@"Discovered device: %@ (Name: %@, RSSI: %@)", deviceUUID, deviceName, RSSI);
    
    NSLog(@"Advertisement Data: %@", advertisementData);
    if (![_connectingPeripherals containsObject:peripheral]) {
        NSLog(@"Connecting to PassBy device: %@", deviceUUID);
        [_connectingPeripherals addObject:peripheral];
        peripheral.delegate = self;
        [_centralManager connectPeripheral:peripheral options:nil];
    } else {
        NSLog(@"Already connecting to device: %@", deviceUUID);
    }
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"Peripheral Manager powered on");
            if (_isAdvertising) {
                [self startAdvertising];
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
        
        // Notify failure via bridge
        std::string errorMessage = std::string([error.localizedDescription UTF8String]);
        PassBy::PassByBridge::onAdvertisingStarted("", false, errorMessage);
    } else {
        NSLog(@"Started advertising successfully with device identifier: %@", self.deviceIdentifier);
        
        // Notify success with fixed device identifier via bridge using getter
        NSString *identifierString = self.deviceIdentifier;  // Use getter for validation
        std::string deviceIdString = std::string([identifierString UTF8String]);
        PassBy::PassByBridge::onAdvertisingStarted(deviceIdString, true);
    }
}

#pragma mark - CBPeripheralDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to peripheral: %@", peripheral.identifier.UUIDString);
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kPassByServiceUUID]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from peripheral: %@", peripheral.identifier.UUIDString);
    [_connectingPeripherals removeObject:peripheral];
    
    if (error) {
        NSLog(@"Disconnection error: %@", error.localizedDescription);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to peripheral: %@ with error: %@", peripheral.identifier.UUIDString, error.localizedDescription);
    [_connectingPeripherals removeObject:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering services: %@", error.localizedDescription);
        [_centralManager cancelPeripheralConnection:peripheral];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:kPassByServiceUUID]) {
            NSLog(@"Found PassBy service, discovering characteristics");
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kPassByDeviceIdentifierUUID]] 
                                      forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverCharacteristicsForService:(CBService *)service 
             error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristics: %@", error.localizedDescription);
        [_centralManager cancelPeripheralConnection:peripheral];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:kPassByDeviceIdentifierUUID]) {
            NSLog(@"Found device identifier characteristic, reading value");
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error {
    if (error) {
        NSLog(@"Error reading characteristic: %@", error.localizedDescription);
        [_centralManager cancelPeripheralConnection:peripheral];
        return;
    }
    
    if ([characteristic.UUID.UUIDString isEqualToString:kPassByDeviceIdentifierUUID]) {
        NSString *deviceIdentifier = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        
        NSLog(@"Retrieved device identifier: %@ from peripheral: %@", deviceIdentifier, peripheral.identifier.UUIDString);
        
        // Report to C++ layer via bridge using the custom identifier
        if (deviceIdentifier && deviceIdentifier.length > 0) {
            PassBy::PassByBridge::onDeviceDiscovered([deviceIdentifier UTF8String]);
        } else {
            // Fallback to system identifier if custom identifier is invalid
            PassBy::PassByBridge::onDeviceDiscovered([@"invalid-device-UUID" UTF8String]);
        }
        
        // Disconnect to free resources
        [_centralManager cancelPeripheralConnection:peripheral];
    }
    else {
        NSLog(@"Received update for characteristic: %@, but not the device identifier", characteristic.UUID.UUIDString);
    }
}

@end