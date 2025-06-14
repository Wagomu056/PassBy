//
//  ViewController.m
//  iOSPassBySample
//
//  Created by 東口拓也 on 2025/06/14.
//

#import "ViewController.h"
#include <PassBy/PassBy.h>
#include <PassBy/PassByBridge.h>
#include <PassBy/PassByTypes.h>
#include <memory>

@interface ViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UITextView *devicesTextView;
@end

@implementation ViewController {
    std::unique_ptr<PassBy::PassByManager> _passbyManager;
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
        
        [self.startButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:20],
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
    // Create PassBy manager
    _passbyManager = std::make_unique<PassBy::PassByManager>();
    
    // Set up bridge to receive callbacks
    PassBy::PassByBridge::setManager(_passbyManager.get());
    
    // Set up device discovery callback
    _passbyManager->setDeviceDiscoveredCallback([self](const PassBy::DeviceInfo& device) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onDeviceDiscovered:device];
        });
    });
}

- (void)startButtonTapped {
    if (_passbyManager->startScanning()) {
        self.statusLabel.text = @"PassBy Status: Scanning";
        NSLog(@"Started BLE scanning");
    } else {
        NSLog(@"Failed to start BLE scanning");
    }
}

- (void)stopButtonTapped {
    if (_passbyManager->stopScanning()) {
        self.statusLabel.text = @"PassBy Status: Stopped";
        NSLog(@"Stopped BLE scanning");
    } else {
        NSLog(@"Failed to stop BLE scanning");
    }
}

- (void)onDeviceDiscovered:(const PassBy::DeviceInfo&)device {
    NSString *deviceUUID = [NSString stringWithUTF8String:device.uuid.c_str()];
    NSLog(@"Device discovered: %@", deviceUUID);
    
    // Update devices list
    auto discoveredDevices = _passbyManager->getDiscoveredDevices();
    NSMutableString *devicesText = [[NSMutableString alloc] initWithString:@"Discovered Devices:\n"];
    
    for (const auto& uuid : discoveredDevices) {
        [devicesText appendFormat:@"• %s\n", uuid.c_str()];
    }
    
    self.devicesTextView.text = devicesText;
}

@end
