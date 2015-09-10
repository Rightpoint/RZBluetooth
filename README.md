# RZBluetooth
RZBluetooth is a Core Bluetooth helper with 3 primary goals:
 - Simplify the delegate callbacks and encourage best practices
 - Provide a pattern for Profile level APIs, with support for public profiles
 - Simplify and encourage testing - including unit tests, automated integration tests, and manual tests.

# Quick Start
To emphasis how easy RZBluetooth is, the following block of code will print out the heart rate of the first heart rate monitor that comes nearby, every time a new reading is available..

```
self.centralManager = [[RZBCentralManager alloc] init];
[self.centralManager scanForPeripheralsWithServices:@[CBUUID rzb_UUIDForHeartRateService] options:@{} onDiscoveredPeripheral:^(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI) {
    [self.centralManager stopScan];
    [peripheral rzb_addHeartRateObserver:^(RZBHeartRateMeasurement *measurement, NSError *error) {
        NSLog(@"%@", measurement);
    } completion:^(NSError *error) {
        if (error) {
            NSLog(@"Error=%@", error);
        }
    }];
}];
```
Obviously a real application would have more concerns than this, but the complexity of CoreBluetooth should not be one of them.

# Install
RZBluetooth is available through CocoaPods. To install it, add the following line to your Podfile:

```
# Not published on cocoapods yet!
pod 'RZBluetooth', :git => "https://github.com/Raizlabs/RZBluetooth"
```

# Usage
There are a few patterns of behaviors an application with Bluetooth will perform:

1. Discover peripherals that the application can interact with.
2. Availability Interactions with a known peripheral
3. User interaction with a known peripheral.

## Scanning
Scaning for new peripherals is usually a user initiated action that collects all near by devices, and allows the user to confirm the device they want to interact with. Be sure to specify the UUID of the required service. 

Think through the UX of your application

1. Prompt the user to perform any required device action to make the device appear. Most heart rate monitors will not be discoverable unless they are worn.
2. Do you need a list of near by devices to select from? Can you tell the user that too many devices were found and the other devices should be turned off?
3. If there are multiple devices, how does the user ensure the proper device is selected?
4. What type of security is used? Initiate the SSN pairing process by reading or writing a secured property before completing selection.


## Availability Interactions
Availability Interactions are a set of actions that should be performed every time the device becomes available. Device Sync is usually built on top of this. All transport layer errors should be ignored, and most other errors would be fatal. RZBluetooth provides a helper for this functionality:

```
[self.centralManager maintainConnectionToPeripheralUUID:peripheralUUID 
                                           onConnection:^(CBPeripheral *peripheral, NSError *error) {
    // Perform actions here
}];
```

## User Interactions
CoreBluetooth and RZBluetooth actions do not time out. When performing actions initiated by the user, make sure that you provide some timeout mechanism so the user knows there's an issue.

```
// Timeouts will be built into RZBluetooth soon!
```

# Features

## Delegate Management
Core Bluetooth has many intermediary callbacks that need to be handled before the desired data can be read, written or observed. RZBluetooth provides a CBCentralManager wrapper that extends CBPeripheral with block based APIs for interacting with characteristics. All connection and discovery operations are performed behind the scenes relaying any intermediary errors up to the user exposed blocks.

```
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
```
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
 - In direct CoreBluetooth, more read and write characteristics cause terrible if chains in the delegate. RZBluetooth allows separation of communication code, such that different bluetooth services can be written and supported in isolation. This allows the development of isolated "Profile" level APIs.

## Profile level APIs
Application level code does not want to read and write NSData blobs. The APIs They want Profile level APIs that work with whatever domain knowledge the services and characteristics encapsulate. RZBluetooth comes with APIs for many of the standard bluetooth profiles, and these provide a pattern for developers to extend RZBluetooth to support thier proprietary profiles.

```
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
CoreBluetooth can be challenging to test. RZBluetooth comes with a library RZMockBluetooth that allows you to use mock Core Bluetooth objects to test your bluetooth and application code. The first step is writing a "Device Simulator" using the CBPeripheralManager API provided by Core Bluetooth. This Device Simulator can then be ran on a mac or another iOS device to simulate your hardware during development. This small development effort decouples the device development effort with the application development and greatly help.

However, this does not help your unit tests. RZBMockBluetooth is able to make a simulated connection between your application CBCentralManager and the CBPeripheralManager to connect your application code to your device simulator in memory. RZBSimulatedConnection allows the test developer to control connection, discoverability, RSSI, scanning, the timing of callbacks, and injection of errors through a simple API. With very little effort your device will connect and talk with your simulator. With slightly more effort, the test developer can reproduce various edge cases and error scenarios.


