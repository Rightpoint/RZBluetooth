//
//  RZBCentralManagerCallbackTests.m
//  RZBluetooth
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralTestCase.h"
#import "RZBPeripheral+Private.h"
#import "CBUUID+TestUUIDs.h"
#import "RZBTestDefines.h"

static NSString *const RZBTestString = @"StringValue";

@interface RZBCentralManagerCallbackTests : RZBMockCentralTestCase

@end

@implementation RZBCentralManagerCallbackTests

- (void)triggerDisconnectionError
{
    [self.mockCentralManager fakeDisconnectPeripheralWithUUID:NSUUID.pUUID
                                                        error:[NSError rzb_connectionError]];
    [self waitForQueueFlush];
}

- (void)testCentralStateWitholding
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    // Perform a read, and ensure that nothing occurs while state == Unknown.
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {}];
    [self waitForQueueFlush];

    RZBAssertCommandCount(1);
    RZBAssertHasCommand(RZBReadCharacteristicCommand, RZBUUIDPath.cUUIDPath, NO);

    // Turn the power on and ensure that a connect command is created and triggered
    // the proper CB method
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    [self waitForQueueFlush];

    // With CB powered on, the connect command should go through.
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(connectPeripheral:options:)], peripheral.corePeripheral);

    // Fail the command to terminate all pending commands.
    [self.mockCentralManager fakeConnectPeripheralWithUUID:NSUUID.pUUID error:[NSError errorWithDomain:RZBluetoothErrorDomain code:0 userInfo:nil]];
    [self waitForQueueFlush];
}

- (void)performCentralStateErrorForState:(CBManagerState)state
{
    __block NSError *readError = nil;
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    // Perform a read, and ensure that nothing occurs while state == Unknown.
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                readError = error;
                            }];
    [self waitForQueueFlush];

    RZBAssertCommandCount(1);
    RZBAssertHasCommand(RZBReadCharacteristicCommand, RZBUUIDPath.cUUIDPath, NO);

    // Turn the power off and ensure that an error is generated
    // the proper CB method
    [self.mockCentralManager fakeStateChange:state];
    [self waitForQueueFlush];
    XCTAssert(self.centralManager.state == state);
    XCTAssertNotNil(readError);
    XCTAssert([readError.domain isEqualToString:RZBluetoothErrorDomain]);
    XCTAssert(readError.code == state);
}

- (void)testCentralStateErrorPoweredOff
{
    [self performCentralStateErrorForState:CBManagerStatePoweredOff];
}

- (void)testCentralStateErrorUnauthorized
{
    [self performCentralStateErrorForState:CBManagerStateUnauthorized];
}

- (void)testCentralStateErrorUnsupported
{
    [self performCentralStateErrorForState:CBManagerStateUnsupported];
}

- (void)testRead
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    __block NSString *value = nil;
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                            }];
    RZBAssertHasCommand(RZBReadCharacteristicCommand, RZBUUIDPath.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfService:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:CBUUID.cUUID serviceUUID:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];
    RZBAssertHasCommand(RZBReadCharacteristicCommand, RZBUUIDPath.cUUIDPath, YES);

    CBMutableService *s = [mockPeripheral serviceForUUID:CBUUID.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:CBUUID.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(readValueForCharacteristic:)], c);

    [mockPeripheral fakeCharacteristic:c updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];
    XCTAssertEqualObjects(RZBTestString, value);
}

- (void)testWrite
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    NSData *writeValue = [RZBTestString dataUsingEncoding:NSUTF8StringEncoding];
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    [peripheral writeData:writeValue
       characteristicUUID:CBUUID.cUUID
              serviceUUID:CBUUID.sUUID];
    RZBAssertHasCommand(RZBWriteCharacteristicCommand, RZBUUIDPath.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfService:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:CBUUID.cUUID serviceUUID:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:CBUUID.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:CBUUID.cUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(writeValue:forCharacteristic:type:)], writeValue);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(writeValue:forCharacteristic:type:)], c);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:2 forSelector:@selector(writeValue:forCharacteristic:type:)], @(CBCharacteristicWriteWithoutResponse));
}

- (void)testWriteWithReply
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    NSData *writeValue = [RZBTestString dataUsingEncoding:NSUTF8StringEncoding];
    __block BOOL completed = NO;
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    [peripheral writeData:writeValue
       characteristicUUID:CBUUID.cUUID
              serviceUUID:CBUUID.sUUID
               completion:^(CBCharacteristic *characteristic, NSError *error) {
                   completed = YES;
               }];
    RZBAssertHasCommand(RZBWriteCharacteristicCommand, RZBUUIDPath.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfService:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:CBUUID.cUUID serviceUUID:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:CBUUID.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:CBUUID.cUUID];
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
    RZBPeripheral *p = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    [p cancelConnectionWithCompletion:^(NSError * _Nullable error) {
        completed = YES;
    }];
    RZBAssertHasCommand(RZBCancelConnectionCommand, RZBUUIDPath.pUUIDPath, NO);

    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBCancelConnectionCommand, RZBUUIDPath.pUUIDPath, YES);
    XCTAssertFalse(completed);
    [self.mockCentralManager fakeDisconnectPeripheralWithUUID:NSUUID.pUUID error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(completed);
}

-(void)testNotify
{
    [self notifyHelper:NO disconnectOrUnsubscribe:NO];
}

-(void)testNotifyAndDisconnect
{
    [self notifyHelper:YES disconnectOrUnsubscribe:NO];
}

-(void)testNotifyAndUnsubscribe
{
    [self notifyHelper:YES disconnectOrUnsubscribe:YES];
}

-(void)notifyHelper:(BOOL)errorOnUnsubscribe disconnectOrUnsubscribe:(BOOL)disconnectOrUnsubscribe
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    peripheral.notifyUnsubscription = errorOnUnsubscribe;
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    NSMutableArray *values = [NSMutableArray array];
    __block NSError* notifyError = nil;
    __block BOOL completed = NO;
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    
    [peripheral enableNotifyForCharacteristicUUID:CBUUID.cUUID
                                      serviceUUID:CBUUID.sUUID
                                         onUpdate:^(CBCharacteristic *c, NSError *error) {
                                             if (error) {
                                                 notifyError = error;
                                             }
                                             else {
                                                 [values addObject:[[NSString alloc] initWithData:c.value encoding:NSUTF8StringEncoding]];
                                             }
                                         } completion:^(CBCharacteristic *c, NSError *error) {
                                             completed = YES;
                                         }];
    
    RZBAssertHasCommand(RZBNotifyCharacteristicCommand, RZBUUIDPath.cUUIDPath, NO);

    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfService:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:CBUUID.cUUID serviceUUID:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:CBUUID.sUUID];
    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:CBUUID.cUUID];
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
    XCTAssertNil(notifyError);

    if (errorOnUnsubscribe) {
        if (disconnectOrUnsubscribe) {
            [self.mockCentralManager fakeDisconnectPeripheralWithUUID:NSUUID.pUUID error:nil];
        }
        else {
            [mockPeripheral fakeCharacteristic:c notify:NO error:nil];
        }
        [self waitForQueueFlush];

        XCTAssert([notifyError.domain isEqualToString:RZBluetoothErrorDomain] && notifyError.code == RZBluetoothNotifyUnsubscribed);
    }
    else {
        XCTAssertNil(notifyError);
    }
}

- (void)testCentralStateErrorGeneration
{
    NSArray *triggeringValues = @[@(CBManagerStateUnsupported), @(CBManagerStateUnauthorized), @(CBManagerStatePoweredOff)];
    NSArray *nonTriggeringValues = @[@(CBManagerStateUnknown), @(CBManagerStatePoweredOn), @(CBManagerStateResetting)];
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
    self.centralManager.centralStateHandler = ^(CBManagerState state) {
        [handledStates addObject:@(state)];
    };

    NSArray *states = @[@(CBManagerStateUnsupported), @(CBManagerStateUnauthorized), @(CBManagerStatePoweredOff), @(CBManagerStateUnknown), @(CBManagerStatePoweredOn), @(CBManagerStateResetting)];

    for (NSNumber *state in states) {
        [self.mockCentralManager fakeStateChange:[state unsignedIntegerValue]];
    }
    [self waitForQueueFlush];

    XCTAssertEqualObjects(handledStates, states);
}

- (void)testScan
{
    NSMutableArray *values = [NSMutableArray array];
    NSDictionary* options = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES };
    NSArray* services = @[CBUUID.sUUID];
    [self.centralManager scanForPeripheralsWithServices:services
                                                options:options
                                 onDiscoveredPeripheral:^(RZBScanInfo *scanInfo, NSError *error)
     {
         [values addObject:scanInfo.peripheral.identifier];
         XCTAssertTrue(scanInfo.advInfo.count == 0);
         XCTAssertTrue(scanInfo.RSSI.integerValue == 55);
     }];
    [self waitForQueueFlush];

    RZBAssertCommandCount(1);
    RZBAssertHasCommand(RZBScanCommand, nil, NO);
    
    RZBScanCommand* cmd = (RZBScanCommand *)[self.centralManager.dispatch commandOfClass:[RZBScanCommand class]
                                                                        matchingUUIDPath:nil
                                                                               createNew:NO];
    XCTAssertEqual(cmd.scanOptions, options);
    XCTAssertEqual(cmd.serviceUUIDs, services);

    // Turn the power on and ensure that a scan command is created and triggered
    // the proper CB method
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
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
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    NSMutableArray *values = [NSMutableArray array];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                            }];
    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];

    // Make sure the first service discovery is sent
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverServiceCommand, RZBUUIDPath.pUUIDPath, YES);

    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[CBUUID.sUUID]);
    [self.invocationLog removeAllLogs];

    // Make a second read to another service
    [peripheral readCharacteristicUUID:CBUUID.c2UUID
                           serviceUUID:CBUUID.s2UUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                            }];

    [self waitForQueueFlush];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[CBUUID.s2UUID]);
    [self.invocationLog removeAllLogs];

    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[CBUUID.sUUID] error:nil];
    [self waitForQueueFlush];

    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[CBUUID.s2UUID] error:nil];
    [self waitForQueueFlush];

    CBMutableService *s = [mockPeripheral serviceForUUID:CBUUID.sUUID];
    CBMutableService *s2 = [mockPeripheral serviceForUUID:CBUUID.s2UUID];

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[CBUUID.cUUID] forService:s error:nil];
    [self waitForQueueFlush];

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[CBUUID.c2UUID] forService:s2 error:nil];
    [self waitForQueueFlush];

    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:CBUUID.cUUID];
    CBMutableCharacteristic *c2 = [s2 rzb_characteristicForUUID:CBUUID.c2UUID];

    [mockPeripheral fakeCharacteristic:c updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [mockPeripheral fakeCharacteristic:c2 updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, (@[RZBTestString, RZBTestString]));
}

- (void)testMultipleCharacteristicDiscoveries
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    NSMutableArray *values = [NSMutableArray array];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                            }];
    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];

    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[CBUUID.sUUID] error:nil];
    [self waitForQueueFlush];
    CBMutableService *s = [mockPeripheral serviceForUUID:CBUUID.sUUID];

    // Make sure the first characteristic command has been dispatched
    RZBAssertHasCommand(RZBDiscoverCharacteristicCommand, RZBUUIDPath.sUUIDPath, YES);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[CBUUID.cUUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);
    [self.invocationLog removeAllLogs];

    // Make a second read to another characteristic
    [peripheral readCharacteristicUUID:CBUUID.c2UUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                [values addObject:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                            }];
    [self waitForQueueFlush];

    // Ensure there are two triggered commands
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, RZBUUIDPath.sUUIDPath, YES, 2);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[CBUUID.c2UUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);
    [self.invocationLog removeAllLogs];

    // Complete the discovery
    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[CBUUID.cUUID] forService:s error:nil];
    [self waitForQueueFlush];
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, RZBUUIDPath.sUUIDPath, YES, 1);

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[CBUUID.c2UUID] forService:s error:nil];
    [self waitForQueueFlush];
    RZBAssertHasCommands(RZBDiscoverCharacteristicCommand, RZBUUIDPath.sUUIDPath, YES, 0);

    CBMutableCharacteristic *c = [s rzb_characteristicForUUID:CBUUID.cUUID];
    CBMutableCharacteristic *c2 = [s rzb_characteristicForUUID:CBUUID.c2UUID];

    [mockPeripheral fakeCharacteristic:c updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [mockPeripheral fakeCharacteristic:c2 updateValue:[RZBTestString dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    [self waitForQueueFlush];

    XCTAssertEqualObjects(values, (@[RZBTestString, RZBTestString]));
}

- (void)testUndiscoveredService
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    NSMutableArray *errors = [NSMutableArray array];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.s2UUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
    // Respond to the discover without any services.
    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[] error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(errors.count == 2);
    for (NSError *discoverError in errors) {
        XCTAssertTrue([discoverError.domain isEqualToString:RZBluetoothErrorDomain]);
        XCTAssertTrue(discoverError.code == RZBluetoothDiscoverServiceError);
        XCTAssertEqualObjects(discoverError.userInfo[RZBluetoothUndiscoveredUUIDsKey], (@[CBUUID.sUUID, CBUUID.s2UUID]));
    }
}

- (void)testUndiscoveredCharacteristic
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    NSMutableArray *errors = [NSMutableArray array];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [peripheral readCharacteristicUUID:CBUUID.c2UUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfService:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];

    CBMutableService *s = [mockPeripheral serviceForUUID:CBUUID.sUUID];
    [mockPeripheral fakeDiscoverCharacteristics:@[] forService:s error:nil];
    [self waitForQueueFlush];

    XCTAssertTrue(errors.count == 2);
    for (NSError *discoverError in errors) {
        XCTAssertTrue([discoverError.domain isEqualToString:RZBluetoothErrorDomain]);
        XCTAssertTrue(discoverError.code == RZBluetoothDiscoverCharacteristicError);

        XCTAssertEqualObjects(discoverError.userInfo[RZBluetoothUndiscoveredUUIDsKey], (@[CBUUID.cUUID, CBUUID.c2UUID]));
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
    [self ensureAndCompleteDiscoveryOfService:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];

    [self triggerDisconnectionError];
    XCTAssertTrue(errors.count == 3);
    XCTAssertEqualObjects(errors, (@[[NSError rzb_connectionError], [NSError rzb_connectionError], [NSError rzb_connectionError]]));
}

- (void)testConnectionFailureWithExecutedTerminalCommands
{
    NSMutableArray *errors = [NSMutableArray array];
    [self setupConnectedPeripheral];
    [self triggerThreeCommandsAndStoreErrorsIn:errors];
    [self ensureAndCompleteDiscoveryOfService:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];
    [self ensureAndCompleteDiscoveryOfCharacteristic:CBUUID.cUUID serviceUUID:CBUUID.sUUID peripheralUUID:NSUUID.pUUID];

    [self triggerDisconnectionError];
    XCTAssertTrue(errors.count == 3);
    XCTAssertEqualObjects(errors, (@[[NSError rzb_connectionError], [NSError rzb_connectionError], [NSError rzb_connectionError]]));
}

- (void)testReadRSSI
{
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:NSUUID.pUUID];
    XCTestExpectation *read = [self expectationWithDescription:@"Read RSSI"];
    [peripheral readRSSI:^(NSNumber *RSSI, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(@-88, RSSI);
        [read fulfill];
    }];
    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
    
    [self waitForQueueFlush];
    [mockPeripheral fakeRSSI:@-88 error:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRetrieveConnectedPeripherals
{
    // Try before connecting
    NSArray* connectedPeripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:@[CBUUID.sUUID]];
    XCTAssertNotNil(connectedPeripherals);
    XCTAssertEqual(connectedPeripherals.count, 0);

    // Connect
    [self setupConnectedPeripheral];
    RZBPeripheral *expectedPeripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];

    // Try again after connecting
    connectedPeripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:@[CBUUID.sUUID]];
    XCTAssertNotNil(connectedPeripherals);
    XCTAssertEqual(connectedPeripherals.count, 1);
    XCTAssertEqualObjects(connectedPeripherals[0], expectedPeripheral);
    
    // Try with a wrong service UUID
    connectedPeripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:@[CBUUID.s2UUID]];
    XCTAssertNotNil(connectedPeripherals);
    XCTAssertEqual(connectedPeripherals.count, 0);
    
    // Disconnect and try again
    [self triggerDisconnectionError];
    connectedPeripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:@[CBUUID.sUUID]];
    XCTAssertNotNil(connectedPeripherals);
    XCTAssertEqual(connectedPeripherals.count, 0);
}

- (void)testRetrievePeripherals
{
    NSArray<RZBPeripheral*>* peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[NSUUID.pUUID]];
    XCTAssertNotNil(peripherals);
    XCTAssertEqual(peripherals.count, 1);
    XCTAssertEqual(peripherals.firstObject.identifier, NSUUID.pUUID);
    
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(retrievePeripheralsWithIdentifiers:)], @[NSUUID.pUUID]);
}

@end
