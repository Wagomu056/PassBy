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
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UITextView *devicesTextView;
@end

@implementation ViewController {
    PassBy::PassByManager* _passbyManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupPassBy];
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
    self.serviceUUIDTextField.returnKeyType = UIReturnKeyDone;
    self.serviceUUIDTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.serviceUUIDTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.serviceUUIDTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.serviceUUIDTextField];
    
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
    
    // Devices text view
    self.devicesTextView = [[UITextView alloc] init];
    self.devicesTextView.text = @"Discovered devices will appear here...";
    self.devicesTextView.editable = NO;
    self.devicesTextView.layer.borderColor = [UIColor systemGrayColor].CGColor;
    self.devicesTextView.layer.borderWidth = 1.0;
    self.devicesTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.devicesTextView];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.serviceUUIDTextField.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:20],
        [self.serviceUUIDTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.serviceUUIDTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.startButton.topAnchor constraintEqualToAnchor:self.serviceUUIDTextField.bottomAnchor constant:20],
        [self.startButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.startButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.stopButton.topAnchor constraintEqualToAnchor:self.startButton.bottomAnchor constant:10],
        [self.stopButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.stopButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.devicesTextView.topAnchor constraintEqualToAnchor:self.stopButton.bottomAnchor constant:20],
        [self.devicesTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.devicesTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.devicesTextView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20]
    ]];
}

- (void)setupPassBy {
    // Get singleton PassBy manager (no service UUID needed at creation)
    _passbyManager = &PassBy::PassByManager::getInstance();
    
    // Bridge is automatically set up in PassByManager constructor
    
    // Set up device discovery callback
    _passbyManager->setDeviceDiscoveredCallback([self](const PassBy::DeviceInfo& device) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onDeviceDiscovered:device];
        });
    });
}

- (void)startButtonTapped {
    // Clear previous results
    self.devicesTextView.text = @"Discovered devices will appear here...";
    
    // Get service UUID from text field
    NSString *serviceUUID = self.serviceUUIDTextField.text;
    std::string serviceUUIDString = "";
    if (serviceUUID && serviceUUID.length > 0) {
        serviceUUIDString = std::string([serviceUUID UTF8String]);
    }
    
    // Start scanning with service UUID
    if (_passbyManager->startScanning(serviceUUIDString)) {
        if (serviceUUID && serviceUUID.length > 0) {
            self.statusLabel.text = [NSString stringWithFormat:@"PassBy Status: Scanning for %@", serviceUUID];
            NSLog(@"[sample] Started BLE scanning for service: %@", serviceUUID);
        } else {
            self.statusLabel.text = @"PassBy Status: Scanning all devices";
            NSLog(@"[sample] Started BLE scanning for all devices");
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

- (void)onDeviceDiscovered:(const PassBy::DeviceInfo&)device {
    NSString *deviceUUID = [NSString stringWithUTF8String:device.uuid.c_str()];
    NSLog(@"[sample] Device discovered: %@", deviceUUID);
    
    // Update devices list
    auto discoveredDevices = _passbyManager->getDiscoveredDevices();
    auto currentServiceUUID = _passbyManager->getCurrentServiceUUID();
    
    NSMutableString *devicesText = [[NSMutableString alloc] init];
    if (!currentServiceUUID.empty()) {
        [devicesText appendFormat:@"Scanning for: %s\n\n", currentServiceUUID.c_str()];
    } else {
        [devicesText appendString:@"Scanning for: All devices\n\n"];
    }
    
    [devicesText appendString:@"Discovered Devices:\n"];
    for (const auto& uuid : discoveredDevices) {
        [devicesText appendFormat:@"• %s\n", uuid.c_str()];
    }
    
    self.devicesTextView.text = devicesText;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
