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

centralManager!.scanForPeripheralsWithServices([CBUUID.rzb_UUIDForHeartRateService()], options: nil, onDiscoveredPeripheral: { (peripheral: CBPeripheral?, advInfo: [NSObject : AnyObject]?, RSSI: NSNumber?) in
    guard let centralManager = self.centralManager, peripheral = peripheral else { return }
    centralManager.stopScan()
    self.peripheral = peripheral
    peripheral.rzb_addHeartRateObserver({ (measurement: RZBHeartRateMeasurement?, error: NSError?) in
        guard let heartRate = measurement?.heartRate else { return }
        print("HEART RATE: \(heartRate)")
    }, completion: { (error: NSError?) in
        guard let error = error else { return }
        print("ERROR: \(error)")
    })
}, onError: { (error: NSError?) in
    guard let error = error else { return }
    print("ERROR: \(error)")
})
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
Application level code does not want to read and write `NSData` blobs, it wants Profile level APIs that work with whatever domain knowledge the services and characteristics encapsulate. RZBluetooth comes with APIs for many of the standard bluetooth profiles, and these provide a pattern for developers to extend RZBluetooth to support their proprietary profiles.

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
Core Bluetooth can be challenging to test. RZBluetooth comes with a library, `RZMockBluetooth`, that allows you to use mock Core Bluetooth objects to test your bluetooth and application code. Using the mock library you can fake the discovery and read callbacks to your code, and the objects will consistently manage their mocked state. 

For example:
```obj-c
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    // Triggers: - (void)centralManagerDidUpdateState:(CBCentralManager *)centralManager
    // Configures: centralManager.state == CBCentralManagerStatePoweredOn

    [self.mockCentralManager fakeDisconnectPeripheralWithUUID:identifier
                                                        error:nil];
    // Triggers: - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
    // Configures: peripheral.state = CBPeripheralStateDisconnected
```

# Simulation
In addition, there is a simulation library that uses these mock objects to support the CBPeripheralManager API. This allows a developer to write a peripheral using the CBPeripheralManager API to simulate the bluetooth device they are connecting to. This simulated device can then be used to allow the app to connect to the peripheral with an in-memory simulation (For demos and unit testing), or by running the simulated device in another app, on another device using real bluetooth.

RZBluetooth provides a base class `RZBSimulatedDevice` to help simplify the CBPeripheralManager API and assist integrating with the in-memory bluetooth. This object is a delegate of CBPeripheralManager, and provides an easier API for working with CBPeripheralManager. It also provides support for some common profiles, like battery level, and device info. This RZBSimulatedDevice can be used on top of the mock bluetooth objects, or inside another iOS or Mac App to facilitate integration testing. This small development effort decouples the device development from the application development effort.

## Model Bluetooth Profile
The first step is to configure the bluetooth service and characteristics with Core Bluetooth. For example:

```obj-c
CBMutableService *batteryService = 
    [[CBMutableService alloc] initWithType:[CBUUID rzb_UUIDForBatteryService] primary:NO];
CBMutableCharacteristic *batteryCharacteristic = 
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                       properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyIndicate
                                            value:nil
                                      permissions:CBAttributePermissionsReadable];
batteryService.characteristics = @[batteryCharacteristic];

[self addService:batteryService];
```

This will add a battery service and characteristic with read and indication support. By specifying nil for the value, CoreBluetooth is informed that this is a dynamic value that should be supplied via callbacks. Check out [Setting Up Your Services and Characteristics](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonPeripheralRoleTasks/PerformingCommonPeripheralRoleTasks.html#//apple_ref/doc/uid/TP40013257-CH4-SW3) in the [CoreBluetooth documentation](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/AboutCoreBluetooth/Introduction.html#//apple_ref/doc/uid/TP40013257-CH1-SW1) for more information.


## Handle Bluetooth Events
The next step is to handle the callbacks that CoreBluetooth triggers. This can be a read request, a write request, or a subscription change that is triggered when a characteristic is observed or un-observed. In this example, supplying a fake battery level is relatively trivial.

```obj-c
    __block typeof(self) welf = (id)self;
    [self addReadCallbackForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic] handler:^CBATTError (CBATTRequest *request) {
        NSNumber *batteryNumber = welf.values[RZBBatteryLevelKey];
        uint8_t batteryLevel = [batteryNumber unsignedIntegerValue];
        request.value = [NSData dataWithBytes:&batteryLevel length:1];
        return CBATTErrorSuccess;
    }];
```

This registers a read handler for the battery characteristic that will grab some in-memory state representing the value and respond to the bluetooth request with the new data. This provides a response to the read request, but no method of configuring the battery level.  

Note that RZBSimulatedDevice provides a dictionary `values` to store arbitrary data in. This is provided so characteristics can be added as categories to RZBSimulatedDevice. 

## Expose Developer API

```obj-c
- (void)setBatteryLevel:(uint8_t)level
{
    self.values[RZBBatteryLevelKey] = @(level);
    CBMutableCharacteristic *batteryCharacteristic = [self characteristicForUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]];

    NSData *value = [NSData dataWithBytes:&level length:1];
    [self.peripheralManager updateValue:value
                      forCharacteristic:batteryCharacteristic
                   onSubscribedCentrals:nil];
}

- (uint8_t)batteryLevel
{
    return [self.values[RZBBatteryLevelKey] unsignedIntegerValue];
}
```

Finally, the simulated device should present some developer-facing API for configuring the in-memory state that is being exposed via bluetooth. This implementation also provides indication support to notify any observing peripherals that the battery level has changed. This API can then be used to modify the simulated device state via Unit Tests, an in-memory simulated device HUD, or a custom application.

## Central Instantiation

One design constraint that is required to integrate the simulation is that the `RZBCentralManager` that is usually used must be swapped out with an `RZBTestableCentralManager`. This can be performed in any number of ways, but does have some implementation considerations. The simulation can also be used without RZBluetooth by using `RZBSimulatedCentral` as well.

## Simulated Connections

`RZBMockBluetooth` is able to make a simulated connection between your application’s `CBCentralManager` and the `CBPeripheralManager` to connect your application code to your device simulator in memory. `RZBSimulatedConnection` allows the test developer to control connection, discoverability, RSSI, scanning, the timing of callbacks, and injection of errors through a simple API. 

Examples:
```obj-c
    RZBTestableCentralManager *centralManager = [[RZBTestableCentralManager alloc] init];
    RZBSimulatedCentral *central = centralManager.simulatedCentral;
    NSUUID *identifier = // The identifer for the CBPeripheral.identifer.
    RZBSimulatedConnection *connection = [central connectionForIdentifier:identifier]

    // Disconnect or prevent connection.
    connection.connectable = NO;

    ...runloop spins...

    // Configure the connect callback to inject an error after 1 second on next connection.
    connection.connectCallback.injectError = [NSError rzb_connectionError];
    connection.connectCallback.delay = 1.0;

    ...runloop spins...

    // Become connectable again
    connection.connectable = YES;
```

The connection object has an `RZBSimulatedCallback` for each callback available, like scan, read, write, notify, connect, etc. For most integration testing scenarios only the connectable property is required.

## Unit Tests

The final step is to build a suite of unit tests to validate the behavior of your bluetooth implementation. RZBluetooth provides a baseclass, `RZBSimulatedTestCase` which configures all of the above objects and provides easy access to the connection object. The a good starting example is the [RZBProfileBatteryTests](RZBluetoothTests/RZBProfileBatteryTests.m) which provides some simple read and observation tests.

