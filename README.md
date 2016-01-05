# RZBluetooth
RZBluetooth is a Core Bluetooth helper with 3 primary goals:

 - Simplify the delegate callbacks and encourage best practices
 - Provide a pattern for Profile level APIs, with support for public profiles
 - Simplify and encourage testing - including unit tests, automated integration tests, and manual tests.

# Quick Start
To emphasize how easy RZBluetooth is, the following block of code will print out the heart rate of the first heart rate monitor that comes nearby, every time a new reading is available.

```objc
self.centralManager = [[RZBCentralManager alloc] init];
[self.centralManager scanForPeripheralsWithServices:@[CBUUID rzb_UUIDForHeartRateService] options:@{} onDiscoveredPeripheral:^(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI) {
    [self.centralManager stopScan];
    self.peripheral = peripheral;
    [self.peripheral rzb_addHeartRateObserver:^(RZBHeartRateMeasurement *measurement, NSError *error) {
        NSLog(@"%@", measurement);
    } completion:^(NSError *error) {
        if (error) {
            NSLog(@"Error=%@", error);
        }
    }];
}];
```

Alternatively in Swift:

```swift
centralManager = RZBCentralManager()
        
let heartRateMeasurement: RZBHeartRateUpdateCompletion = { (measurement: RZBHeartRateMeasurement?, error: NSError?) in
    guard let heartRate = measurement?.heartRate else { return }
    print("HEART RATE: \(heartRate)")
 }
        
let heartRateCompletion: RZBHeartRateCompletion  = { (error: NSError?) in
    guard let error = error else { return }
    print("ERROR: \(error)")
}
        
let scanBlock: RZBScanBlock = { (peripheral: CBPeripheral?, advInfo: [NSObject : AnyObject]?, RSSI: NSNumber?) in
    guard let centralManager = self.centralManager, peripheral = peripheral else { return }
    centralManager.stopScan()
    self.peripheral = peripheral
    peripheral.rzb_addHeartRateObserver(heartRateMeasurement, completion: heartRateCompletion)
}

let errorBlock: RZBErrorBlock = { (error: NSError?) in
    guard let error = error else { return }
    print("ERROR: \(error)")
}
        
centralManager!.scanForPeripheralsWithServices(nil, options: nil, onDiscoveredPeripheral: scanBlock, onError: errorBlock)
 ```

This block will wait for bluetooth to power on and scan for a new peripheral supporting the heart rate service. When one is found, the app will connect to the peripheral, discover the heart rate service and observe the characteristic. When the characteristic is notified, the `NSData*` object is serialized into a more developer friendly object. All of these details are nicely encapsulated for you, and the pattern of CBPeripheral categories should be easily extendable to your devices domain space.

# Install
RZBluetooth is available through CocoaPods. To install it, add the following line to your Podfile:

```ruby
pod 'RZBluetooth', :git => "https://github.com/Raizlabs/RZBluetooth"
```

# Usage
There are a few patterns of behavior that most Bluetooth devices conform to:

1. Scanning for peripherals that the application can interact with.
2. Availability Interactions with a known peripheral
3. User interaction with a known peripheral.

## Scanning
Scanning for new peripherals is usually a user-initiated action that collects all nearby devices, and allows the user to confirm the device they want to interact with. Be sure to specify the UUID of the required service.

Think through the UX of your application:

1. Prompt the user to perform any required device action to make the device appear. Most heart rate monitors will not be discoverable unless they are worn.
2. Do you need a list of nearby devices to select from? Can you tell the user that too many devices were found and the other devices should be turned off?
3. If there are multiple devices, how does the user ensure the proper device is selected?
4. What type of security is used? Initiate the SSN pairing process by reading or writing a secured property before completing selection.

Once a device has been selected, the peripheral UUID can be persisted between application starts. Also, it's important to note that the peripheral UUID is unique to the iOS device and should not be shared between computers.


## Availability Interactions
Availability Interactions are a set of actions that should be performed every time the device becomes available. Device Sync is usually built on top of this. All transport layer errors should be ignored, and most other errors would be considered fatal. RZBluetooth provides a helper for this functionality:

```objc
[self.centralManager setConnectionHandlerForPeripheralUUID:p.identifier handler:^(CBPeripheral *peripheral, NSError *error) {
    // Perform actions here
}];
[self.centralManager maintainConnectionToPeripheralUUID:p.identifier];
```

All action performed here will occur every time the device becomes connectable. This usage pattern is extremely important for low power devices that can not maintain a constant connection.

## User Interactions
Core Bluetooth and RZBluetooth actions do not time out by default. User initiated actions however do need to timeout so the UI can inform the user that there's an issue. Also, if there's a terminal bluetooth state (powered off, unsupported, etc) that should also create an error object. This behavior can be easily enabled via the `RZBUserInteraction` object:

```objc
[RZBUserInteraction setTimeout:5.0];
[RZBUserInteraction perform:^{
    [self.peripheral rzb_fetchBatteryLevel:^(NSUInteger level, NSError *error) {
        // The error object could have status code RZBluetoothTimeoutError
}];
}];
```

# Error Handling
All Core Bluetooth errors passed through to the client, however RZBluetooth adds a handful of errors to help clarify some state corner cases.

## CBCentralManagerState
If an action is performed and the central is in a "terminal" state, an error with an error code of `RZBluetooth[Unsupported|Unauthorized|PoweredOff]` will be generated. If the state is Unknown or Resetting, RZBluetooth will wait for the state to become powered on before sending the commands, or will fail the command with an appropriate error.

## Un-Discoverable Services and Characteristics
If an action is performed on a peripheral and the service or characteristic does not exist, an error object will be generated to clearly state the failure scenario. Both `RZBluetoothDiscoverServiceError` and `RZBluetoothDiscoverCharacteristicError` will have a userInfo dictionary with the key `RZBluetoothUndiscoveredUUIDsKey` populated with the undiscovered UUIDs.

## User Initiated Timeout
If an action is performed with `RZBUserInteraction` enabled, and the action takes longer than the timeout, the command will fail, and the completion block will be triggered with an error object. The error code will be `RZBluetoothTimeoutError`.

# Features

## Delegate Management
Core Bluetooth has many intermediary callbacks that need to be handled before the desired data can be read, written or observed. RZBluetooth provides a `CBCentralManager` wrapper that extends `CBPeripheral` with block based APIs for interacting with characteristics. All connection and discovery operations are performed behind the scenes relaying any intermediary errors up to the user exposed blocks.

```objc
- (void)initiateRead
{
    //
    // Very simple, and naive code to read a characteristic.  
    // The lack of error handling, if statements and the use of lastObject would never actually fly.
    //
    CBPeripheral *peripheral = [[self.centralManager retrievePeripheralsWithIdentifiers:@[uuid]] lastObject];
    [self.centralManager connectPeripheral:peripheral options:@{}];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:@[self.class.serviceUUID]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    CBService *service = [peripheral.services lastObject];
    [peripheral discoverCharacteristics:@[self.class.characteristicUUID] forService:service];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    [peripheral readValueForCharacteristic:[service.characteristics lastObject]];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *valueIActuallyWant = characteristic.value;
}
```

*The RZBluetooth way*

```objc
- (void)initiateRead
{
    CBPeripheral *peripheral = [self.centralManager peripheralForUUID:uuid];
    [peripheral readCharacteristicUUID:self.class.characteristicUUID
                           serviceUUID:self.class.serviceUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                       NSData *valueIActuallyWant = characteristic.value;
                            }];
}
```

A few things to note:

 - The peripheral is automatically connected if it is not connected.
 - The service and characteristics are automatically discovered. If they are not supported by the peripheral, an error object will be generated. This is a lot more helpful than an array not having the expected object.
 - Multiple read and write calls will not cause more connect or discover events than required. The discover events are batched up and triggered on the next runloop iteration.
 - In direct Core Bluetooth, more read and write characteristics cause terrible if chains in the delegate. RZBluetooth allows separation of communication code, such that different bluetooth services can be written and supported in isolation. This allows the development of isolated "Profile" level APIs.

## Profile level APIs
Application level code does not want to read and write `NSData` blobs. The APIs They want Profile level APIs that work with whatever domain knowledge the services and characteristics encapsulate. RZBluetooth comes with APIs for many of the standard bluetooth profiles, and these provide a pattern for developers to extend RZBluetooth to support their proprietary profiles.

```objc
- (void)exampleOperations
{
    CBPeripheral *peripheral = [self.centralManager peripheralForUUID:uuid];
    [peripheral rzb_addBatteryLevelObserver:^(NSUInteger batteryLevel, NSError *error) {
        // Update UI for the battery level.
    } completion:^(NSError *error) {
        // Completion indicating that the battery monitor has been setup.
    }];
    [peripheral rzb_readSensorLocation:^(RZBBodyLocation location) {
    }];
    [peripheral rzb_addHeartRateObserver:^(RZBHeartRateMeasurement *measurement, NSError *error) {
    } completion:^(NSError *error) {
    }];
}
```

## Testing
Core Bluetooth can be challenging to test. RZBluetooth comes with a library, `RZMockBluetooth`, that allows you to use mock Core Bluetooth objects to test your bluetooth and application code. The first step is writing a "Device Simulator" using the `CBPeripheralManager` API provided by Core Bluetooth. This Device Simulator can then be run on a Mac or another iOS device to simulate your hardware during development. This small development effort decouples the device development effort with the application development and greatly help.

However, this does not help your unit tests. `RZBMockBluetooth` is able to make a simulated connection between your application’s `CBCentralManager` and the `CBPeripheralManager` to connect your application code to your device simulator in memory. `RZBSimulatedConnection` allows the test developer to control connection, discoverability, RSSI, scanning, the timing of callbacks, and injection of errors through a simple API. With very little effort your device will connect and talk with your simulator. With slightly more effort, the test developer can reproduce various edge cases and error scenarios.


