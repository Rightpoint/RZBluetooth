//
//  RZCentralManagerTests.m
//  UMTSDK
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralTestCase.h"

static NSString *const RZBTestString = @"StringValue";

@interface RZCentralManagerTests : RZBMockCentralTestCase

@end

@implementation RZCentralManagerTests

- (void)triggerDisconnectionError
{
    [self.mockCentralManager fakeDisconnectPeripheralWithUUID:self.class.pUUID
                                                        error:[NSError rzb_connectionError]];
    [self waitForQueueFlush];
}

- (void)testCentralStateWitholding
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    // Perform a read, and ensure that nothing occurs while state == Unknown.
    [p readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {

                   }];
    [self waitForQueueFlush];

    RZBAssertCommandCount(1);
    RZBAssertHasCommand(RZBReadCharacteristicCommand, self.class.cUUIDPath, NO);

    // Turn the power on and ensure that a connect command is created and triggered
    // the proper CB method
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [self waitForQueueFlush];

    // With CB powered on, the connect command should go through.
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(connectPeripheral:options:)], p);

    // Fail the command to terminate all pending commands.
    [self.mockCentralManager fakeConnectPeripheralWithUUID:self.class.pUUID error:[NSError errorWithDomain:RZBluetoothErrorDomain code:0 userInfo:nil]];
    [self waitForQueueFlush];
}

- (void)testRead
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    __block NSString *value = nil;
    [p readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       value = [[NSString alloc] initWithData:peripheral.value encoding:NSUTF8StringEncoding];
                   }];
    RZBAssertHasCommand(RZBReadCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];
    RZBAssertHasCommand(RZBReadCharacteristicCommand, self.class.cUUIDPath, YES);

    RZBMockService *s = [p serviceForUUID:self.class.sUUID];
    RZBMockCharacteristic *c = [s characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(readValueForCharacteristic:)], c);

    [c fakeUpdateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];
    XCTAssertEqualObjects(RZBTestString, value);
}

- (void)testWrite
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    NSData *writeValue = [RZBTestString dataUsingEncoding:NSUTF8StringEncoding];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [p writeData:writeValue
characteristicUUID:self.class.cUUID
     serviceUUID:self.class.sUUID];
    RZBAssertHasCommand(RZBWriteCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];

    RZBMockService *s = [p serviceForUUID:self.class.sUUID];
    RZBMockCharacteristic *c = [s characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(writeValue:forCharacteristic:type:)], writeValue);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(writeValue:forCharacteristic:type:)], c);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:2 forSelector:@selector(writeValue:forCharacteristic:type:)], @(CBCharacteristicWriteWithoutResponse));
}

- (void)testWriteWithReply
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    NSData *writeValue = [RZBTestString dataUsingEncoding:NSUTF8StringEncoding];
    __block BOOL completed = NO;
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [p writeData:writeValue
characteristicUUID:self.class.cUUID
     serviceUUID:self.class.sUUID
      completion:^(CBCharacteristic *peripheral, NSError *error) {
          completed = YES;
      }];
    RZBAssertHasCommand(RZBWriteCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];

    RZBMockService *s = [p serviceForUUID:self.class.sUUID];
    RZBMockCharacteristic *c = [s characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(writeValue:forCharacteristic:type:)], writeValue);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(writeValue:forCharacteristic:type:)], c);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:2 forSelector:@selector(writeValue:forCharacteristic:type:)], @(CBCharacteristicWriteWithResponse));

    [c fakeWriteResponseWithError:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(completed);
}

- (void)testCancelConnection
{
    // Trigger a read just to re-use the setup and connection
    [self testRead];
    __block BOOL completed = NO;
    [self.centralManager cancelConnectionFromPeripheralUUID:self.class.pUUID
                                                 completion:^(CBPeripheral *peripheral, NSError *error) {
                                                     completed = YES;
                                                 }];
    RZBAssertHasCommand(RZBCancelConnectionCommand, self.class.pUUIDPath, NO);

    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBCancelConnectionCommand, self.class.pUUIDPath, YES);
    XCTAssertFalse(completed);
    [self.mockCentralManager fakeDisconnectPeripheralWithUUID:self.class.pUUID error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(completed);
}

- (void)testNotify
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    NSMutableArray *values = [NSMutableArray array];
    __block BOOL completed = NO;
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [p monitorCharacteristicUUID:self.class.cUUID
                     serviceUUID:self.class.sUUID
                        onChange:^(CBCharacteristic *peripheral, NSError *error) {
                            [values addObject:[[NSString alloc] initWithData:peripheral.value encoding:NSUTF8StringEncoding]];
                        } completion:^(CBCharacteristic *peripheral, NSError *error) {
                            completed = YES;
                        }];

    RZBAssertHasCommand(RZBNotifyCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];

    RZBMockService *s = [p serviceForUUID:self.class.sUUID];
    RZBMockCharacteristic *c = [s characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(setNotifyValue:forCharacteristic:)], @(YES));
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(setNotifyValue:forCharacteristic:)], c);

    [c fakeNotify:YES error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(completed);

    NSArray *updateValues = @[@"One", @"Two", @"Three"];
    for (NSString *value in updateValues) {
        [c fakeUpdateValue:[value dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    }
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, updateValues);
}

- (void)testCentralStateIssueBlock
{
    NSMutableArray *values = [NSMutableArray array];
    NSArray *triggeringValues = @[@(CBCentralManagerStateUnsupported), @(CBCentralManagerStateUnauthorized), @(CBCentralManagerStatePoweredOff)];
    NSArray *nonTriggeringValues = @[@(CBCentralManagerStateUnknown), @(CBCentralManagerStatePoweredOn), @(CBCentralManagerStateResetting)];
    self.centralManager.centralStateIssueHandler = ^(CBCentralManagerState state) {
        [values addObject:@(state)];
    };

    for (NSNumber *triggeringValue in triggeringValues) {
        [self.mockCentralManager fakeStateChange:[triggeringValue unsignedIntegerValue]];
    }
    for (NSNumber *nonTriggeringValue in nonTriggeringValues) {
        [self.mockCentralManager fakeStateChange:[nonTriggeringValue unsignedIntegerValue]];
    }
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, triggeringValues);
}

- (void)testScan
{
    NSMutableArray *values = [NSMutableArray array];
    [self.centralManager scanForPeripheralsWithServices:@[self.class.sUUID]
                                                options:nil
                                 onDiscoveredPeripheral:^(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI)
     {
         [values addObject:peripheral.identifier];
         XCTAssertTrue(advInfo.count == 0);
         XCTAssertTrue(RSSI.integerValue == 55);
     }];
    [self waitForQueueFlush];

    RZBAssertCommandCount(1);
    RZBAssertHasCommand(RZBScanCommand, nil, NO);

    // Turn the power on and ensure that a scan command is created and triggered
    // the proper CB method
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBScanCommand, nil, YES);

    NSArray *peripherals = @[[NSUUID UUID], [NSUUID UUID], [NSUUID UUID]];
    for (NSUUID *identifier in peripherals) {
        [self.mockCentralManager fakeScanPeripheralWithUUID:identifier advInfo:@{} RSSI:@(55)];
    }

    [self waitForQueueFlush];
    XCTAssertEqualObjects(peripherals, values);

    [self.centralManager stopScan];
}

- (void)testMultipleServiceDiscoveries
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *values = [NSMutableArray array];
    [p readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       [values addObject:[[NSString alloc] initWithData:peripheral.value encoding:NSUTF8StringEncoding]];
                   }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];

    // Make sure the first service discovery is sent
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverServiceCommand, self.class.pUUIDPath, YES);

    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[self.class.sUUID]);
    [self.invocationLog removeAllLogs];

    // Make a second read to another service
    [p readCharacteristicUUID:self.class.c2UUID
                  serviceUUID:self.class.s2UUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       [values addObject:[[NSString alloc] initWithData:peripheral.value encoding:NSUTF8StringEncoding]];
                   }];

    [self waitForQueueFlush];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[self.class.s2UUID]);
    [self.invocationLog removeAllLogs];

    [p fakeDiscoverServicesWithUUIDs:@[self.class.sUUID] error:nil];
    [self waitForQueueFlush];

    [p fakeDiscoverServicesWithUUIDs:@[self.class.s2UUID] error:nil];
    [self waitForQueueFlush];

    RZBMockService *s = [p serviceForUUID:self.class.sUUID];
    RZBMockService *s2 = [p serviceForUUID:self.class.s2UUID];

    [s fakeDiscoverCharacteristicsWithUUIDs:@[self.class.cUUID] error:nil];
    [self waitForQueueFlush];

    [s2 fakeDiscoverCharacteristicsWithUUIDs:@[self.class.c2UUID] error:nil];
    [self waitForQueueFlush];

    RZBMockCharacteristic *c = [s characteristicForUUID:self.class.cUUID];
    RZBMockCharacteristic *c2 = [s2 characteristicForUUID:self.class.c2UUID];

    [c fakeUpdateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [c2 fakeUpdateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, (@[RZBTestString, RZBTestString]));
}

- (void)testMultipleCharacteristicDiscoveries
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *values = [NSMutableArray array];
    [p readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       [values addObject:[[NSString alloc] initWithData:peripheral.value encoding:NSUTF8StringEncoding]];
                   }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];

    [p fakeDiscoverServicesWithUUIDs:@[self.class.sUUID] error:nil];
    [self waitForQueueFlush];
    RZBMockService *s = [p serviceForUUID:self.class.sUUID];

    // Make sure the first characteristic command has been dispatched
    RZBAssertHasCommand(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[self.class.cUUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);
    [self.invocationLog removeAllLogs];

    // Make a second read to another characteristic
    [p readCharacteristicUUID:self.class.c2UUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       [values addObject:[[NSString alloc] initWithData:peripheral.value encoding:NSUTF8StringEncoding]];
                   }];
    [self waitForQueueFlush];

    // Ensure there are two triggered commands
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES, 2);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[self.class.c2UUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);
    [self.invocationLog removeAllLogs];

    // Complete the discovery
    [s fakeDiscoverCharacteristicsWithUUIDs:@[self.class.cUUID] error:nil];
    [self waitForQueueFlush];
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES, 1);

    [s fakeDiscoverCharacteristicsWithUUIDs:@[self.class.c2UUID] error:nil];
    [self waitForQueueFlush];
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES, 0);

    RZBMockCharacteristic *c = [s characteristicForUUID:self.class.cUUID];
    RZBMockCharacteristic *c2 = [s characteristicForUUID:self.class.c2UUID];

    [c fakeUpdateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [c2 fakeUpdateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, (@[RZBTestString, RZBTestString]));
}

- (void)testUndiscoveredService
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *errors = [NSMutableArray array];
    [p readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       XCTAssertNotNil(error);
                       [errors addObject:error];
                   }];
    [p readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.s2UUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       XCTAssertNotNil(error);
                       [errors addObject:error];
                   }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    // Respond to the discover without any services.
    [p fakeDiscoverServicesWithUUIDs:@[] error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(errors.count == 2);
    for (NSError *discoverError in errors) {
        XCTAssertTrue([discoverError.domain isEqualToString:RZBluetoothErrorDomain]);
        XCTAssertTrue(discoverError.code == RZBluetoothDiscoverServiceError);
        XCTAssertEqualObjects(discoverError.userInfo[RZBluetoothUndiscoveredUUIDsKey], (@[self.class.sUUID, self.class.s2UUID]));
    }
}

- (void)testUndiscoveredCharacteristic
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *errors = [NSMutableArray array];
    [p readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       XCTAssertNotNil(error);
                       [errors addObject:error];
                   }];
    [p readCharacteristicUUID:self.class.c2UUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *peripheral, NSError *error) {
                       XCTAssertNotNil(error);
                       [errors addObject:error];
                   }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];

    RZBMockService *s = [p serviceForUUID:self.class.sUUID];
    [s fakeDiscoverCharacteristics:@[] error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(errors.count == 2);
    for (NSError *discoverError in errors) {
        XCTAssertTrue([discoverError.domain isEqualToString:RZBluetoothErrorDomain]);
        XCTAssertTrue(discoverError.code == RZBluetoothDiscoverCharacteristicError);

        XCTAssertEqualObjects(discoverError.userInfo[RZBluetoothUndiscoveredUUIDsKey], (@[self.class.cUUID, self.class.c2UUID]));
    }
}

- (void)testConnectionFailureInServiceDiscovery
{
    NSMutableArray *errors = [NSMutableArray array];
    [self setupConnectedPeripheral];
    [self triggerThreeCommandsAndStoreErrorsIn:errors];
    [self triggerDisconnectionError];

    // Fake the disconnect error
    XCTAssertTrue(errors.count == 3);
    XCTAssertEqualObjects(errors, (@[[NSError rzb_connectionError], [NSError rzb_connectionError], [NSError rzb_connectionError]]));
}

- (void)testConnectionFailureInCharacteristicDiscovery
{
    NSMutableArray *errors = [NSMutableArray array];
    [self setupConnectedPeripheral];
    [self triggerThreeCommandsAndStoreErrorsIn:errors];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];

    [self triggerDisconnectionError];
    XCTAssertTrue(errors.count == 3);
    XCTAssertEqualObjects(errors, (@[[NSError rzb_connectionError], [NSError rzb_connectionError], [NSError rzb_connectionError]]));
}

- (void)testConnectionFailureWithExecutedTerminalCommands
{
    NSMutableArray *errors = [NSMutableArray array];
    [self setupConnectedPeripheral];
    [self triggerThreeCommandsAndStoreErrorsIn:errors];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];

    [self triggerDisconnectionError];
    XCTAssertTrue(errors.count == 3);
    XCTAssertEqualObjects(errors, (@[[NSError rzb_connectionError], [NSError rzb_connectionError], [NSError rzb_connectionError]]));
}

- (void)testAutoConnection
{
}

@end
