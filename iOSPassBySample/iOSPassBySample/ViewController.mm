//
//  ViewController.m
//  iOSPassBySample
//
//  Created by 東口拓也 on 2025/06/14.
//

#import "ViewController.h"
#include <PassBy/PassBy.h>
#include <PassBy/PassByTypes.h>
#include <memory>

@interface ViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITextField *serviceUUIDTextField;
@property (nonatomic, strong) UITextField *deviceIdentifierTextField;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *getDevicesButton;
@property (nonatomic, strong) UITextView *getDevicesResultTextView;
@property (nonatomic, strong) UILabel *backgroundLabel;
@property (nonatomic, strong) UITextView *backgroundLogTextView;
@property (nonatomic, strong) UIButton *clearLogButton;
@end

@implementation ViewController {
    PassBy::PassByManager* _passbyManager;
    NSMutableArray<NSString*>* _backgroundLog;
    NSDateFormatter* _dateFormatter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeComponents];
    [self setupUI];
    [self setupPassBy];
    [self setupNotificationObservers];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Status label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"PassBy Status: Stopped";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];
    
    // Service UUID text field
    self.serviceUUIDTextField = [[UITextField alloc] init];
    self.serviceUUIDTextField.placeholder = @"Service UUID (empty = all devices)";
    self.serviceUUIDTextField.text = @"12345678-1234-1234-1234-123456789ABC";
    self.serviceUUIDTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.serviceUUIDTextField.delegate = self;
    self.serviceUUIDTextField.returnKeyType = UIReturnKeyNext;
    self.serviceUUIDTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.serviceUUIDTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.serviceUUIDTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.serviceUUIDTextField];
    
    // Device Identifier text field
    self.deviceIdentifierTextField = [[UITextField alloc] init];
    self.deviceIdentifierTextField.placeholder = @"Device Identifier (for advertising)";
    self.deviceIdentifierTextField.text = @"iPhone-Takuya";
    self.deviceIdentifierTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.deviceIdentifierTextField.delegate = self;
    self.deviceIdentifierTextField.returnKeyType = UIReturnKeyDone;
    self.deviceIdentifierTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.deviceIdentifierTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.deviceIdentifierTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.deviceIdentifierTextField];
    
    // Start button
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.startButton setTitle:@"Start BLE Scanning" forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(startButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.startButton];
    
    // Stop button
    self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.stopButton setTitle:@"Stop BLE Scanning" forState:UIControlStateNormal];
    [self.stopButton addTarget:self action:@selector(stopButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.stopButton];
    
    // Get devices button
    self.getDevicesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.getDevicesButton setTitle:@"Get Discovered Devices" forState:UIControlStateNormal];
    [self.getDevicesButton addTarget:self action:@selector(getDevicesButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.getDevicesButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.getDevicesButton];
    
    // Get devices result text view
    self.getDevicesResultTextView = [[UITextView alloc] init];
    self.getDevicesResultTextView.text = @"Results will appear here...";
    self.getDevicesResultTextView.editable = NO;
    self.getDevicesResultTextView.layer.borderColor = [UIColor systemGrayColor].CGColor;
    self.getDevicesResultTextView.layer.borderWidth = 1.0;
    self.getDevicesResultTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.getDevicesResultTextView];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.serviceUUIDTextField.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:20],
        [self.serviceUUIDTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.serviceUUIDTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.deviceIdentifierTextField.topAnchor constraintEqualToAnchor:self.serviceUUIDTextField.bottomAnchor constant:10],
        [self.deviceIdentifierTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.deviceIdentifierTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.startButton.topAnchor constraintEqualToAnchor:self.deviceIdentifierTextField.bottomAnchor constant:20],
        [self.startButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.startButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.stopButton.topAnchor constraintEqualToAnchor:self.startButton.bottomAnchor constant:10],
        [self.stopButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.stopButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.getDevicesButton.topAnchor constraintEqualToAnchor:self.stopButton.bottomAnchor constant:20],
        [self.getDevicesButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.getDevicesButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.getDevicesResultTextView.topAnchor constraintEqualToAnchor:self.getDevicesButton.bottomAnchor constant:10],
        [self.getDevicesResultTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.getDevicesResultTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.getDevicesResultTextView.heightAnchor constraintEqualToConstant:120]
    ]];
    
    // Background detection section
    self.backgroundLabel = [[UILabel alloc] init];
    self.backgroundLabel.text = @"Background Detection Log:";
    self.backgroundLabel.font = [UIFont boldSystemFontOfSize:16];
    self.backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundLabel];
    
    // Clear log button
    self.clearLogButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearLogButton setTitle:@"Clear Log" forState:UIControlStateNormal];
    [self.clearLogButton addTarget:self action:@selector(clearLogButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.clearLogButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.clearLogButton];
    
    // Background log text view
    self.backgroundLogTextView = [[UITextView alloc] init];
    self.backgroundLogTextView.text = @"Background detection results will appear here...";
    self.backgroundLogTextView.editable = NO;
    self.backgroundLogTextView.layer.borderColor = [UIColor systemOrangeColor].CGColor;
    self.backgroundLogTextView.layer.borderWidth = 1.0;
    self.backgroundLogTextView.font = [UIFont systemFontOfSize:12];
    self.backgroundLogTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundLogTextView];
    
    // Additional layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundLabel.topAnchor constraintEqualToAnchor:self.getDevicesResultTextView.bottomAnchor constant:20],
        [self.backgroundLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.backgroundLabel.widthAnchor constraintEqualToConstant:200],
        
        [self.clearLogButton.topAnchor constraintEqualToAnchor:self.getDevicesResultTextView.bottomAnchor constant:20],
        [self.clearLogButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.clearLogButton.widthAnchor constraintEqualToConstant:80],
        
        [self.backgroundLogTextView.topAnchor constraintEqualToAnchor:self.backgroundLabel.bottomAnchor constant:10],
        [self.backgroundLogTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.backgroundLogTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.backgroundLogTextView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20]
    ]];
}

- (void)initializeComponents {
    _backgroundLog = [[NSMutableArray alloc] init];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"HH:mm:ss"];
}

- (void)setupPassBy {
    // Get singleton PassBy manager (no service UUID needed at creation)
    _passbyManager = &PassBy::PassByManager::getInstance();
    
    // Bridge is automatically set up in PassByManager constructor
    
    // Set up device discovery callback
    _passbyManager->setDeviceDiscoveredCallback([self](const PassBy::DeviceInfo& device) {
        PassBy::DeviceInfo deviceCopy = device;
        // Core Bluetooth callbacks are executed on background thread,
        // so dispatch to main queue for UI updates
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onDeviceDiscovered:deviceCopy];
        });
    });
}

- (void)startButtonTapped {
    // Get service UUID from text field
    NSString *serviceUUID = self.serviceUUIDTextField.text;
    std::string serviceUUIDString = "";
    if (serviceUUID && serviceUUID.length > 0) {
        serviceUUIDString = std::string([serviceUUID UTF8String]);
    }
    
    // Get device identifier from text field
    NSString *deviceIdentifier = self.deviceIdentifierTextField.text;
    std::string deviceIdentifierString = "";
    if (deviceIdentifier && deviceIdentifier.length > 0) {
        deviceIdentifierString = std::string([deviceIdentifier UTF8String]);
    }
    
    // Start scanning with service UUID and device identifier
    if (_passbyManager->startScanning(serviceUUIDString, deviceIdentifierString)) {
        if (serviceUUID && serviceUUID.length > 0) {
            self.statusLabel.text = [NSString stringWithFormat:@"PassBy Status: Scanning for %@", serviceUUID];
            NSLog(@"[sample] Started BLE scanning for service: %@ with device ID: %@", serviceUUID, deviceIdentifier);
        } else {
            self.statusLabel.text = @"PassBy Status: Scanning all devices";
            NSLog(@"[sample] Started BLE scanning for all devices with device ID: %@", deviceIdentifier);
        }
    } else {
        NSLog(@"[sample] Failed to start BLE scanning");
    }
}

- (void)stopButtonTapped {
    if (_passbyManager && _passbyManager->stopScanning()) {
        self.statusLabel.text = @"PassBy Status: Stopped";
        NSLog(@"[sample] Stopped BLE scanning");
    } else {
        NSLog(@"[sample] Failed to stop BLE scanning");
    }
}

- (void)getDevicesButtonTapped {
    // Clear previous results
    self.getDevicesResultTextView.text = @"";
    
    if (_passbyManager) {
        auto discoveredDevices = _passbyManager->getDiscoveredDevices();
        
        NSMutableString *resultText = [[NSMutableString alloc] init];
        [resultText appendFormat:@"Total discovered devices: %lu\n\n", (unsigned long)discoveredDevices.size()];
        
        if (discoveredDevices.empty()) {
            [resultText appendString:@"No devices discovered yet."];
        } else {
            [resultText appendString:@"Device UUIDs:\n"];
            for (const auto& uuid : discoveredDevices) {
                [resultText appendFormat:@"• %s\n", uuid.c_str()];
            }
        }
        
        self.getDevicesResultTextView.text = resultText;
        NSLog(@"[sample] getDiscoveredDevices called - found %lu devices", (unsigned long)discoveredDevices.size());
    } else {
        self.getDevicesResultTextView.text = @"Error: PassBy manager not initialized";
        NSLog(@"[sample] Error: PassBy manager not initialized");
    }
}

- (void)onDeviceDiscovered:(const PassBy::DeviceInfo&)device {
    // Safe UUID conversion
    NSString *deviceUUID = @"<INVALID UUID>";
    if (!device.uuid.empty()) {
        const char* cString = device.uuid.c_str();
        if (cString && strlen(cString) > 0) {
            deviceUUID = [NSString stringWithUTF8String:cString];
        }
    }
    
    // Safe device hash conversion
    NSString *deviceHash = @"";
    if (!device.deviceHash.empty()) {
        const char* hashCString = device.deviceHash.c_str();
        if (hashCString && strlen(hashCString) > 0) {
            deviceHash = [NSString stringWithUTF8String:hashCString];
        }
    }
    
    NSString *timestamp = [_dateFormatter stringFromDate:[NSDate date]];
    NSString *appState = [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground ? @"Background" : @"Foreground";
    
    NSString *logEntry;
    if (deviceHash.length > 0) {
        logEntry = [NSString stringWithFormat:@"[%@] %@: %@ (Hash: %@)", timestamp, appState, deviceUUID, deviceHash];
    } else {
        logEntry = [NSString stringWithFormat:@"[%@] %@: %@", timestamp, appState, deviceUUID];
    }
    [_backgroundLog addObject:logEntry];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateBackgroundLogDisplay];
    });
    
    if (deviceHash.length > 0) {
        NSLog(@"[sample] Device discovered (%@): %@ (Hash: %@)", appState, deviceUUID, deviceHash);
    } else {
        NSLog(@"[sample] Device discovered (%@): %@", appState, deviceUUID);
    }
}

- (void)clearLogButtonTapped {
    [_backgroundLog removeAllObjects];
    [self updateBackgroundLogDisplay];
    NSLog(@"[sample] Background log cleared");
}

- (void)updateBackgroundLogDisplay {
    if (_backgroundLog.count == 0) {
        self.backgroundLogTextView.text = @"Background detection results will appear here...";
    } else {
        self.backgroundLogTextView.text = [_backgroundLog componentsJoinedByString:@"\n"];
        
        // Auto-scroll to bottom
        NSRange bottom = NSMakeRange(self.backgroundLogTextView.text.length - 1, 1);
        [self.backgroundLogTextView scrollRangeToVisible:bottom];
    }
}

- (void)setupNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSString *timestamp = [_dateFormatter stringFromDate:[NSDate date]];
    NSString *logEntry = [NSString stringWithFormat:@"[%@] App entered background", timestamp];
    [_backgroundLog addObject:logEntry];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateBackgroundLogDisplay];
    });
    
    NSLog(@"[sample] App entered background - BLE scanning should continue");
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    NSString *timestamp = [_dateFormatter stringFromDate:[NSDate date]];
    NSString *logEntry = [NSString stringWithFormat:@"[%@] App returned to foreground", timestamp];
    [_backgroundLog addObject:logEntry];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateBackgroundLogDisplay];
    });
    
    NSLog(@"[sample] App returned to foreground");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.serviceUUIDTextField) {
        [self.deviceIdentifierTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

@end
