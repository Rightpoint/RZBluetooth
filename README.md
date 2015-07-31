# RZBluetooth
RZBluetooth is a Core Bluetooth helper with 3 primary goals:
 - Simplify the delegate callbacks and encourage best practices
 - Provide a pattern for Profile level API's
 - Simplify and encourage testing - including unit tests, automated integration tests, and manual tests.

## Delegate Management
Core Bluetooth has many intermediary callbacks that need to be handled before the desired data can be read, written or observed. RZBluetooth provides a CBCentralManager wrapper that extends CBPeripheral will block based API's for interacting with characteristics. All connection and discovery operations are performed behind the scenes relaying any intermediary errors up to the user exposed operations.

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
 - The peripheral is automatically connected. Any connection error is relayed to the completion block.
 - The service and characteristics are automatically discovered. If they are not supported by the peripheral, an error object will be generated. This is a lot more helpful than an array not having the expected object.
 - Multiple read and write calls will not cause more connect or discover events than required.
 - In direct CoreBluetooth, more read and write calls cause terrible if chains in the delegate. RZBluetooth allows separation of communication code, such that different bluetooth services can be written and supported in isolation. This allows the development of isolated "Profile" level API's.

## Profile level API's
Application level code working with Core Bluetooth does not want to read and write NSData blobs. They want Profile level API's that work with whatever domain knowledge the services and characteristics encapsulate. RZBluetooth comes with API's for many of the standard bluetooth profiles, and these provide a pattern for developers to extend RZBluetooth to support thier proprietary profiles.

```
- (void)exampleOperations
{
    // FIXME: THESE NEED TO ACTUALY BE IMPLEMENTED
    CBPeripheral *peripheral = [self.centralManager peripheralForUUID:uuid];
    [peripheral monitorBatteryLevel:^(NSUInteger batteryLevel) {
        // Update UI for the battery level.
    } completion:^(NSError *error) {
        // Completion indicating that the battery monitor has been setup.
    }];
    [peripheral fetchDeviceInformation:^(NSDictionary *deviceInfo, NSError *error) {
    }];
}
```

## Testing
CoreBluetooth is challenging to test. RZBluetooth comes with a library RZMockBluetooth that provides 3 methods of testing your application.

 - Mock Objects to manually control your interactions in Unit Tests.
 - Mock Peripherals to fake your devices bluetooth structure. These simulated peripherals use the mock objects to interact with your automated tests in a simpler fashion.
 - Simulated Peripherals that take the simulated device written above, but run in a stand alone application and pretend to be your device. 


