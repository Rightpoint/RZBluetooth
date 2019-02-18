//
//  RZBSimulatedTests.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"

@interface RZBSimulatedTests : RZBSimulatedTestCase <RZBPeripheralConnectionDelegate>

@property (nonatomic, assign) NSUInteger connectCount;
@property (nonatomic, assign) NSUInteger connectFailureCount;
@property (nonatomic, assign) NSUInteger disconnectCount;

@end

@implementation RZBSimulatedTests

- (void)peripheral:(RZBPeripheral *)peripheral connectionEvent:(RZBPeripheralStateEvent)event error:(NSError *)error;
{
    switch (event) {
        case RZBPeripheralStateEventConnectSuccess:
            self.connectCount++;
            break;
        case RZBPeripheralStateEventConnectFailure:
            self.connectFailureCount++;
            break;
        case RZBPeripheralStateEventDisconnected:
            self.disconnectCount++;
            break;
    }
}

- (void)testScanForDevices
{
    XCTestExpectation *discovered = [self expectationWithDescription:@"Peripheral will connect"];

    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:nil
                                 onDiscoveredPeripheral:^(RZBScanInfo *scanInfo, NSError *error) {
                                     [discovered fulfill];
                                     XCTAssert([scanInfo.peripheral.identifier isEqual:self.connection.identifier]);
                                 }];
    [self.device.peripheralManager startAdvertising:@{}];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [self.centralManager stopScan];
}

- (void)testScanWithDisconnect
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral connected"];
    __block RZBPeripheral *peripheral = nil;

    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:nil
                                 onDiscoveredPeripheral:^(RZBScanInfo *scanInfo, NSError *error) {
                                     XCTAssertNil(peripheral);
                                     XCTAssertNil(error);
                                     peripheral = scanInfo.peripheral;
                                     peripheral.connectionDelegate = self;

                                     [peripheral connectWithCompletion:^(NSError * _Nullable connectError) {
                                         XCTAssertNil(connectError);
                                         [connected fulfill];
                                     }];
                                 }];
    [self.device.peripheralManager startAdvertising:@{}];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssert(self.connectCount == 1);
    self.connection.cancelConncetionCallback.injectError = [NSError rzb_connectionError];
    self.connection.connectable = NO;

    [self waitForQueueFlush];
    XCTAssert(self.connectCount == 1);
    XCTAssert(self.disconnectCount == 1);

    [self.centralManager stopScan];

    [self waitForQueueFlush];
}

- (void)testConnection
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.connection.identifier];
    [peripheral connectWithCompletion:^(NSError * _Nullable error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.connection.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionError
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    self.connection.connectCallback.injectError = [NSError rzb_connectionError];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.connection.identifier];
    [peripheral connectWithCompletion:^(NSError * _Nullable error) {
        [connected fulfill];
        XCTAssertNotNil(error);
        XCTAssert([peripheral.identifier isEqual:self.connection.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectable
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.connection.identifier];
    XCTAssert(peripheral.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [peripheral connectWithCompletion:^(NSError * _Nullable error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.connection.identifier]);
    }];
    [self waitForQueueFlush];
    XCTAssert(peripheral.state == CBPeripheralStateConnecting);

    self.connection.connectable = YES;
    XCTAssert(peripheral.state == CBPeripheralStateConnecting);

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssert(peripheral.state == CBPeripheralStateConnected);
}

- (void)testConnectionAndCancelWhileNotConnectable
{
    XCTestExpectation *connectCallback = [self expectationWithDescription:@"Connect Callback"];
    XCTestExpectation *cancelConnectCallback = [self expectationWithDescription:@"Connect Cancelation Callback"];

    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.connection.identifier];
    XCTAssert(peripheral.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [peripheral connectWithCompletion:^(NSError *error) {
        XCTAssertNil(error);
        [connectCallback fulfill];
    }];
    [self waitForQueueFlush];
    XCTAssert(peripheral.state == CBPeripheralStateConnecting);

    [peripheral cancelConnectionWithCompletion:^(NSError *error) {
        XCTAssertNil(error);
        [cancelConnectCallback fulfill];
    }];
    [self waitForQueueFlush];

    self.connection.connectable = YES;
    [self waitForQueueFlush];
    XCTAssert(peripheral.state == CBPeripheralStateDisconnected);

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testMaintainConnection
{
    self.disconnectCount = 0;
    self.connectCount = 0;
    self.connectFailureCount = 0;
    RZBPeripheral *p = [self.centralManager peripheralForUUID:self.connection.identifier];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;
    p.connectionDelegate = self;
    p.maintainConnection = YES;

#define TEST_COUNT 10
    for (NSUInteger i = 0; i < TEST_COUNT; i++) {
        [self waitForQueueFlush];
        XCTAssert(p.state == CBPeripheralStateConnecting);

        self.connection.connectable = YES;
        [self waitForQueueFlush];
        XCTAssert(p.state == CBPeripheralStateConnected);
        XCTAssert(self.connectCount == i + 1);

        // Disable the connection maintenance on the last iteration.
        if (i == TEST_COUNT - 1) {
            [p cancelConnectionWithCompletion:nil];
        }
        else {
            self.connection.connectable = NO;
        }
        [self waitForQueueFlush];
        XCTAssert(self.disconnectCount == i + 1);
    }
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    XCTAssert(self.connectFailureCount == 0);
}

- (void)testStateBounce
{
    [self.device addBatteryService];

    // Configure the peripheral, set up the observer, and wait for connection
    RZBPeripheral *p = [self.centralManager peripheralForUUID:self.connection.identifier];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    p.connectionDelegate = self;
    p.maintainConnection = YES;
    NSMutableArray *values = [NSMutableArray array];
    [p addBatteryLevelObserver:^(NSUInteger level, NSError *error) {
        [values addObject:@(level)];
    } completion:^(NSError *error) {
    }];
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateConnected);

    self.connection.connectable = NO;
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateConnecting);

    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOff];
    [self.connection reset];
    [self waitForQueueFlush];

    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    self.connection.connectable = YES;
    [self waitForQueueFlush];

    [p addBatteryLevelObserver:^(NSUInteger level, NSError *error) {
        [values addObject:@(level)];
    } completion:^(NSError *error) {
    }];
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateConnected);
    
    // Change the battery level and ensure the observer is notified of the new battery level
    self.device.batteryLevel = 88;
    [self waitForQueueFlush];
    XCTAssertEqualObjects(values, @[@88]);

}

- (CBATTError)mockUpdateOnCharacteristicUUID:(CBUUID *)uuid withValue:(NSData *)value
{
    CBMutableCharacteristic* characteristic = [self.device characteristicForUUID:uuid];
    if (characteristic != nil) {
        if ([self.device.peripheralManager updateValue:value forCharacteristic:characteristic onSubscribedCentrals:nil]) {
            return CBATTErrorSuccess;
        }
    }
    return CBATTErrorRequestNotSupported;
}

- (CBATTError)mockUpdateOnCharacteristicUUID:(CBUUID *)uuid serviceUUID:(CBUUID *)serviceUUID withValue:(NSData *)value
{
    CBMutableCharacteristic* characteristic = [self.device characteristicForUUID:uuid serviceUUID:serviceUUID];
    if (characteristic != nil) {
        if ([self.device.peripheralManager updateValue:value forCharacteristic:characteristic onSubscribedCentrals:nil]) {
            return CBATTErrorSuccess;
        }
    }
    return CBATTErrorRequestNotSupported;
}

- (void)testStaticCharacteristics
{
    __block int staticCallbackCount  = 0;
    __block int dynamicCallbackCount = 0;
    
    NSString *staticValue = @"static";
    __block NSString *newStaticValue  = @"foobar";
    __block NSString *dynamicValue    = @"expected";
    
    CBUUID *uuid = [CBUUID UUIDWithString:@"AC764575-B8D2-4DB0-9D04-D8A7F270CE8B"];
    CBMutableService *testService = [[CBMutableService alloc] initWithType:uuid primary:YES];
    
    CBUUID *staticUUID = [CBUUID UUIDWithString:@"18266046"];
    CBMutableCharacteristic *staticChar = [[CBMutableCharacteristic alloc] initWithType:staticUUID
                                                                             properties:CBCharacteristicPropertyRead
                                                                                  value:[staticValue dataUsingEncoding:NSUTF8StringEncoding]
                                                                            permissions:CBAttributePermissionsReadable];
    CBUUID *dynamicUUID = [CBUUID UUIDWithString:@"35FF1332"];
    CBMutableCharacteristic *dynamicChar = [[CBMutableCharacteristic alloc] initWithType:dynamicUUID
                                                                              properties:CBCharacteristicPropertyRead
                                                                                   value:nil
                                                                             permissions:CBAttributePermissionsReadable];
    testService.characteristics = @[staticChar, dynamicChar];
    
    [self.device addService:testService];
    
    __block typeof(self) welf = (id)self;
    [self.device addReadCallbackForCharacteristicUUID:staticUUID handler:^CBATTError(CBATTRequest * _Nonnull request) {
        staticCallbackCount++;
        return [welf mockUpdateOnCharacteristicUUID:staticUUID withValue:[newStaticValue dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    [self.device addReadCallbackForCharacteristicUUID:dynamicUUID handler:^CBATTError(CBATTRequest * _Nonnull request) {
        dynamicCallbackCount++;
        return [welf mockUpdateOnCharacteristicUUID:dynamicUUID withValue:[dynamicValue dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // Configure the peripheral
    RZBPeripheral *p = [self.centralManager peripheralForUUID:self.connection.identifier];
    
    // Read both static and dynamic characteristics
    [p readCharacteristicUUID:staticUUID serviceUUID:testService.UUID completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNotNil(value);
        
        NSString *string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
        XCTAssertTrue([string isEqualToString:staticValue]);
    }];
    [p readCharacteristicUUID:dynamicUUID serviceUUID:testService.UUID completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNotNil(value);
        
        NSString *string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
        XCTAssertTrue([string isEqualToString:dynamicValue]);
    }];
    [self waitForQueueFlush];
    
    // Modify the dynamic value and try it again
    dynamicValue   = @"updated";
    [p readCharacteristicUUID:staticUUID serviceUUID:testService.UUID completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNotNil(value);
        
        NSString *string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
        XCTAssertTrue([string isEqualToString:staticValue]);
    }];
    [p readCharacteristicUUID:dynamicUUID serviceUUID:testService.UUID completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNotNil(value);
        
        NSString *string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
        XCTAssertTrue([string isEqualToString:dynamicValue]);
    }];
    [self waitForQueueFlush];
    
    // Remove the service and read callbacks and try it again
    [self.device removeReadCallbackForCharacteristicUUID:staticUUID];
    [self.device removeReadCallbackForCharacteristicUUID:dynamicUUID];
    [self.device removeService:testService];

    [p readCharacteristicUUID:staticUUID serviceUUID:testService.UUID completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNil(value);
        XCTAssertNotNil(error);
    }];
    [p readCharacteristicUUID:dynamicUUID serviceUUID:testService.UUID completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNil(value);
        XCTAssertNotNil(error);
    }];
    [self waitForQueueFlush];

    XCTAssertEqual(staticCallbackCount,  0);
    XCTAssertEqual(dynamicCallbackCount, 2);
    
}

- (void)testSameCharacteristicOnTwoServices
{
    NSString *char1Value = @"Char 1 Value";
    NSData *char1Data = [char1Value dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *char2Value = @"Char 2 Value";
    NSData *char2Data = [char2Value dataUsingEncoding:NSUTF8StringEncoding];
    
    CBUUID *suuid1 = [CBUUID UUIDWithString:@"AC764575-B8D2-4DB0-9D04-D8A7F270CE8B"];
    CBMutableService *testService1 = [[CBMutableService alloc] initWithType:suuid1 primary:YES];
    
    CBUUID *suuid2 = [CBUUID UUIDWithString:@"9E986B01-8CB2-46CB-8415-3FF8F0505885"];
    CBMutableService *testService2 = [[CBMutableService alloc] initWithType:suuid2 primary:YES];
    
    CBUUID *cuuid = [CBUUID UUIDWithString:@"1826"];
    CBMutableCharacteristic *char1 = [[CBMutableCharacteristic alloc] initWithType:cuuid
                                                                        properties:CBCharacteristicPropertyRead
                                                                             value:nil
                                                                       permissions:CBAttributePermissionsReadable];
    
    CBMutableCharacteristic *char2 = [[CBMutableCharacteristic alloc] initWithType:cuuid
                                                                        properties:CBCharacteristicPropertyRead
                                                                             value:nil
                                                                       permissions:CBAttributePermissionsReadable];
    testService1.characteristics = @[char1];
    testService2.characteristics = @[char2];

    [self.device addService:testService1];
    [self.device addService:testService2];
    
    __block int char1CallbackCount = 0;
    __block int char2CallbackCount = 0;
    
    __block typeof(self) welf = (id)self;
    
    // Without the additional serviceUUID: parameter these 2 calls would now throw an assertion failure.
    [self.device addReadCallbackForCharacteristicUUID:cuuid serviceUUID:suuid1 handler:^CBATTError(CBATTRequest * _Nonnull request) {
        char1CallbackCount++;
        return [welf mockUpdateOnCharacteristicUUID:cuuid serviceUUID:suuid1 withValue:char1Data];
    }];
    [self.device addReadCallbackForCharacteristicUUID:cuuid serviceUUID:suuid2 handler:^CBATTError(CBATTRequest * _Nonnull request) {
        char2CallbackCount++;
        return [welf mockUpdateOnCharacteristicUUID:cuuid serviceUUID:suuid2 withValue:char2Data];
    }];
    
    // Configure the peripheral
    RZBPeripheral *p = [self.centralManager peripheralForUUID:self.connection.identifier];
    
    // Read both static and dynamic characteristics
    [p readCharacteristicUUID:cuuid serviceUUID:suuid1 completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNotNil(value);
        
        NSString *string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
        XCTAssertTrue([string isEqualToString:char1Value]);
    }];
    [p readCharacteristicUUID:cuuid serviceUUID:suuid2 completion:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) {
        NSData *value = characteristic.value;
        XCTAssertNotNil(value);
        
        NSString *string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
        XCTAssertTrue([string isEqualToString:char2Value]);
    }];
    [self waitForQueueFlush];
    
    XCTAssertEqual(char1CallbackCount, 1);
    XCTAssertEqual(char2CallbackCount, 1);
}

@end
