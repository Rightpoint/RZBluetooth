//
//  RZCentralManagerTests.m
//  UMTSDK
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralTestCase.h"
#import "RZBPeripheral+Private.h"

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
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    // Perform a read, and ensure that nothing occurs while state == Unknown.
    [peripheral readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *characteristic, NSError *error) {

                   }];
    [self waitForQueueFlush];

    RZBAssertCommandCount(1);
    RZBAssertHasCommand(RZBReadCharacteristicCommand, self.class.cUUIDPath, NO);

    // Turn the power on and ensure that a connect command is created and triggered
    // the proper CB method
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [self waitForQueueFlush];

    // With CB powered on, the connect command should go through.
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(connectPeripheral:options:)], peripheral.corePeripheral);

    // Fail the command to terminate all pending commands.
    [self.mockCentralManager fakeConnectPeripheralWithUUID:self.class.pUUID error:[NSError errorWithDomain:RZBluetoothErrorDomain code:0 userInfo:nil]];
    [self waitForQueueFlush];
}

- (void)testRead
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    __block NSString *value = nil;
    [peripheral readCharacteristicUUID:self.class.cUUID
                  serviceUUID:self.class.sUUID
                   completion:^(CBCharacteristic *characteristic, NSError *error) {
                       value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                   }];
    RZBAssertHasCommand(RZBReadCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];
    RZBAssertHasCommand(RZBReadCharacteristicCommand, self.class.cUUIDPath, YES);

    CBMutableService *s = [mockPeripheral serviceForUUID:self.class.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(readValueForCharacteristic:)], c);

    [mockPeripheral fakeCharacteristic:c updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];
    XCTAssertEqualObjects(RZBTestString, value);
}

- (void)testWrite
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    NSData *writeValue = [RZBTestString dataUsingEncoding:NSUTF8StringEncoding];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [peripheral writeData:writeValue
       characteristicUUID:self.class.cUUID
              serviceUUID:self.class.sUUID];
    RZBAssertHasCommand(RZBWriteCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:self.class.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(writeValue:forCharacteristic:type:)], writeValue);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(writeValue:forCharacteristic:type:)], c);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:2 forSelector:@selector(writeValue:forCharacteristic:type:)], @(CBCharacteristicWriteWithoutResponse));
}

- (void)testWriteWithReply
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    NSData *writeValue = [RZBTestString dataUsingEncoding:NSUTF8StringEncoding];
    __block BOOL completed = NO;
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [peripheral writeData:writeValue
  characteristicUUID:self.class.cUUID
         serviceUUID:self.class.sUUID
          completion:^(CBCharacteristic *characteristic, NSError *error) {
              completed = YES;
          }];
    RZBAssertHasCommand(RZBWriteCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:self.class.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(writeValue:forCharacteristic:type:)], writeValue);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(writeValue:forCharacteristic:type:)], c);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:2 forSelector:@selector(writeValue:forCharacteristic:type:)], @(CBCharacteristicWriteWithResponse));

    [mockPeripheral fakeCharacteristic:c writeResponseWithError:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(completed);
}

- (void)testCancelConnection
{
    // Trigger a read just to re-use the setup and connection
    [self testRead];
    __block BOOL completed = NO;
    [self.centralManager cancelConnectionFromPeripheralUUID:self.class.pUUID
                                                 completion:^(RZBPeripheral *peripheral, NSError *error) {
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
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    NSMutableArray *values = [NSMutableArray array];
    __block BOOL completed = NO;
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];

    [peripheral addObserverForCharacteristicUUID:self.class.cUUID
                                     serviceUUID:self.class.sUUID
                                        onChange:^(CBCharacteristic *c, NSError *error) {
                                            [values addObject:[[NSString alloc] initWithData:c.value encoding:NSUTF8StringEncoding]];
                                        } completion:^(CBCharacteristic *c, NSError *error) {
                                            completed = YES;
                                        }];

    RZBAssertHasCommand(RZBNotifyCharacteristicCommand, self.class.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:self.class.cUUID serviceUUID:self.class.sUUID peripheralUUID:self.class.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:self.class.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:self.class.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(setNotifyValue:forCharacteristic:)], @(YES));
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(setNotifyValue:forCharacteristic:)], c);

    [mockPeripheral fakeCharacteristic:c notify:YES error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(completed);

    NSArray *updateValues = @[@"One", @"Two", @"Three"];
    for (NSString *value in updateValues) {
        [mockPeripheral fakeCharacteristic:c updateValue:[value dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    }
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, updateValues);
}

- (void)testCentralStateErrorGeneration
{
    NSArray *triggeringValues = @[@(CBCentralManagerStateUnsupported), @(CBCentralManagerStateUnauthorized), @(CBCentralManagerStatePoweredOff)];
    NSArray *nonTriggeringValues = @[@(CBCentralManagerStateUnknown), @(CBCentralManagerStatePoweredOn), @(CBCentralManagerStateResetting)];
    for (NSNumber *triggeringValue in triggeringValues) {
        XCTAssertNotNil(RZBluetoothErrorForState([triggeringValue unsignedIntegerValue]));
    }
    for (NSNumber *nonTriggeringValue in nonTriggeringValues) {
        XCTAssertNil(RZBluetoothErrorForState([nonTriggeringValue unsignedIntegerValue]));
    }
}

- (void)testCentralStateBlock
{
    NSMutableArray *handledStates = [NSMutableArray array];
    self.centralManager.centralStateHandler = ^(CBCentralManagerState state) {
        [handledStates addObject:@(state)];
    };

    NSArray *states = @[@(CBCentralManagerStateUnsupported), @(CBCentralManagerStateUnauthorized), @(CBCentralManagerStatePoweredOff), @(CBCentralManagerStateUnknown), @(CBCentralManagerStatePoweredOn), @(CBCentralManagerStateResetting)];

    for (NSNumber *state in states) {
        [self.mockCentralManager fakeStateChange:[state unsignedIntegerValue]];
    }
    [self waitForQueueFlush];

    XCTAssertEqualObjects(handledStates, states);
}

- (void)testScan
{
    NSMutableArray *values = [NSMutableArray array];
    [self.centralManager scanForPeripheralsWithServices:@[self.class.sUUID]
                                                options:nil
                                 onDiscoveredPeripheral:^(RZBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI)
     {
         [values addObject:peripheral.identifier];
         XCTAssertTrue(advInfo.count == 0);
         XCTAssertTrue(RSSI.integerValue == 55);
     } onError:nil];
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
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *values = [NSMutableArray array];
    [peripheral readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                       }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];

    // Make sure the first service discovery is sent
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverServiceCommand, self.class.pUUIDPath, YES);

    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[self.class.sUUID]);
    [self.invocationLog removeAllLogs];

    // Make a second read to another service
    [peripheral readCharacteristicUUID:self.class.c2UUID
                      serviceUUID:self.class.s2UUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                       }];

    [self waitForQueueFlush];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[self.class.s2UUID]);
    [self.invocationLog removeAllLogs];

    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[self.class.sUUID] error:nil];
    [self waitForQueueFlush];

    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[self.class.s2UUID] error:nil];
    [self waitForQueueFlush];

    CBMutableService *s = [mockPeripheral serviceForUUID:self.class.sUUID];
    CBMutableService *s2 = [mockPeripheral serviceForUUID:self.class.s2UUID];

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[self.class.cUUID] forService:s error:nil];
    [self waitForQueueFlush];

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[self.class.c2UUID] forService:s2 error:nil];
    [self waitForQueueFlush];

    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:self.class.cUUID];
    CBMutableCharacteristic *c2 = [s2 rzb_characteristicForUUID:self.class.c2UUID];

    [mockPeripheral fakeCharacteristic:c updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [mockPeripheral fakeCharacteristic:c2 updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, (@[RZBTestString, RZBTestString]));
}

- (void)testMultipleCharacteristicDiscoveries
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *values = [NSMutableArray array];
    [peripheral readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                       }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];

    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[self.class.sUUID] error:nil];
    [self waitForQueueFlush];
    CBMutableService *s = [mockPeripheral serviceForUUID:self.class.sUUID];

    // Make sure the first characteristic command has been dispatched
    RZBAssertHasCommand(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[self.class.cUUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);
    [self.invocationLog removeAllLogs];

    // Make a second read to another characteristic
    [peripheral readCharacteristicUUID:self.class.c2UUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                       }];
    [self waitForQueueFlush];

    // Ensure there are two triggered commands
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES, 2);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[self.class.c2UUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);
    [self.invocationLog removeAllLogs];

    // Complete the discovery
    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[self.class.cUUID] forService:s error:nil];
    [self waitForQueueFlush];
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES, 1);

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[self.class.c2UUID] forService:s error:nil];
    [self waitForQueueFlush];
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, self.class.sUUIDPath, YES, 0);

    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:self.class.cUUID];
    CBMutableCharacteristic *c2 = [s rzb_characteristicForUUID:self.class.c2UUID];

    [mockPeripheral fakeCharacteristic:c updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [mockPeripheral fakeCharacteristic:c2 updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, (@[RZBTestString, RZBTestString]));
}

- (void)testUndiscoveredService
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *errors = [NSMutableArray array];
    [peripheral readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           XCTAssertNotNil(error);
                           [errors addObject:error];
                       }];
    [peripheral readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.s2UUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           XCTAssertNotNil(error);
                           [errors addObject:error];
                       }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    // Respond to the discover without any services.
    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[] error:nil];
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
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSMutableArray *errors = [NSMutableArray array];
    [peripheral readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           XCTAssertNotNil(error);
                           [errors addObject:error];
                       }];
    [peripheral readCharacteristicUUID:self.class.c2UUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *characteristic, NSError *error) {
                           XCTAssertNotNil(error);
                           [errors addObject:error];
                       }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];
    [self ensureAndCompleteDiscoveryOfService:self.class.sUUID peripheralUUID:self.class.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:self.class.sUUID];
    [mockPeripheral fakeDiscoverCharacteristics:@[] forService:s error:nil];
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

- (void)testReadRSSI
{
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:self.class.pUUID];
    XCTestExpectation *read = [self expectationWithDescription:@"Read RSSI"];
    [peripheral readRSSI:^(NSNumber *RSSI, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(@-88, RSSI);
        [read fulfill];
    }];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];

    [self waitForQueueFlush];
    [mockPeripheral fakeRSSI:@-88 error:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
