//
//  RZBMockCentralTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralTestCase.h"
#import "NSRunLoop+RZBWaitFor.h"
#import "CBUUID+TestUUIDs.h"

@implementation RZBMockCentralTestCase

- (void)waitForQueueFlush
{
    BOOL done = [[NSRunLoop currentRunLoop] rzb_waitWithTimeout:2.0 forCheck:^BOOL{
        return self.centralManager.dispatch.dispatchCounter == 0;
    }];
    XCTAssert(done);
}

- (RZBMockCentralManager *)mockCentralManager
{
    RZBMockCentralManager *mockCentral = (id)self.centralManager.coreCentralManager;
    NSAssert([mockCentral isKindOfClass:[RZBMockCentralManager class]], @"Invalid central");
    return mockCentral;
}

- (void)setUp
{
    [super setUp];
    RZBEnableMock(YES);
    self.centralManager = [[RZBCentralManager alloc] init];
    self.mockCentralManager.mockDelegate = self;
    self.invocationLog = [[RZBInvocationLog alloc] init];
}

- (void)tearDown
{
    // All tests should end with no pending commands.
    RZBAssertCommandCount(0);
    self.centralManager = nil;
    [super tearDown];
}

- (void)ensureAndCompleteConnectionTo:(NSUUID *)peripheralUUID
{
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBConnectCommand, RZBUUIDP(peripheralUUID), YES);

    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(connectPeripheral:options:)], mockPeripheral);

    // Fake the connection, and ensure the discover commands occurred.
    [self.mockCentralManager fakeConnectPeripheralWithUUID:peripheralUUID error:nil];
    [self waitForQueueFlush];
}

- (void)ensureAndCompleteDiscoveryOfService:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID
{
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverServiceCommand, RZBUUIDPath.pUUIDPath, YES);

    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[serviceUUID]);

    // Fake the service discovery
    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[CBUUID.sUUID] error:nil];
    [self waitForQueueFlush];
}

- (void)ensureAndCompleteDiscoveryOfCharacteristic:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID
{
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverCharacteristicCommand, RZBUUIDP(peripheralUUID, serviceUUID), YES);

    RZBMockPeripheral *mockPeripheral = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    CBMutableService *s = [mockPeripheral serviceForUUID:serviceUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[characteristicUUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[characteristicUUID] forService:s error:nil];

    [self waitForQueueFlush];
}

- (void)triggerThreeCommandsAndStoreErrorsIn:(NSMutableArray *)errors
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [peripheral readCharacteristicUUID:CBUUID.cUUID
                           serviceUUID:CBUUID.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [self waitForQueueFlush];
}

- (void)setupConnectedPeripheral
{
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:NSUUID.pUUID];

    [peripheral connectWithCompletion:^(NSError *error) {}];
    [self ensureAndCompleteConnectionTo:NSUUID.pUUID];
}

#pragma mark Delegate -> Invocation Log.

// Small macro to transform the delegate method to the originating method.
#define C_CMD NSSelectorFromString([NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString:@"mockCentralManager:" withString:@""])
#define P_CMD NSSelectorFromString([NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString:@"mockPeripheral:" withString:@""])

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;
{
    for (NSUUID *identifier in identifiers) {
        RZBMockPeripheral *mockPeripheral = [mockCentralManager peripheralForUUID:identifier];
        mockPeripheral.mockDelegate = self;
    }
    [self.invocationLog logSelector:C_CMD arguments:identifiers];
}

- (NSArray *)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs
{
    NSMutableArray *result = [NSMutableArray array];
    if ([serviceUUIDs containsObject:CBUUID.sUUID]) {
        RZBMockPeripheral *peripheral = [mockCentralManager peripheralForUUID:NSUUID.pUUID];
        if (peripheral.state == CBPeripheralStateConnected) {
            [result addObject:peripheral];
        }
    }
    [self.invocationLog logSelector:C_CMD arguments:serviceUUIDs];
    return result;
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    [self.invocationLog logSelector:C_CMD arguments:services, options];
}

- (void)mockCentralManagerStopScan:(RZBMockCentralManager *)mockCentralManager
{
    [self.invocationLog logSelector:@selector(stopScan) arguments:nil];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager connectPeripheral:(RZBMockPeripheral *)mockPeripheral options:(NSDictionary *)options
{
    [self.invocationLog logSelector:C_CMD arguments:mockPeripheral, options];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)mockPeripheral
{
    [self.invocationLog logSelector:C_CMD arguments:mockPeripheral];
}

- (void)mockPeripheral:(RZBMockPeripheral *)mockPeripheral discoverServices:(NSArray *)serviceUUIDs
{
    [self.invocationLog logSelector:P_CMD arguments:serviceUUIDs];
}

- (void)mockPeripheral:(RZBMockPeripheral *)mockPeripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service
{
    [self.invocationLog logSelector:P_CMD arguments:characteristicUUIDs, service];
}

- (void)mockPeripheral:(RZBMockPeripheral *)mockPeripheral readValueForCharacteristic:(CBCharacteristic *)characteristic
{
    [self.invocationLog logSelector:P_CMD arguments:characteristic];
}

- (void)mockPeripheral:(RZBMockPeripheral *)mockPeripheral writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [self.invocationLog logSelector:P_CMD arguments:data, characteristic, @(type)];
}

- (void)mockPeripheral:(RZBMockPeripheral *)mockPeripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic
{
    [self.invocationLog logSelector:P_CMD arguments:@(enabled), characteristic];
}

- (void)mockPeripheralReadRSSI:(RZBMockPeripheral *)mockPeripheral
{
    [self.invocationLog logSelector:@selector(readRSSI) arguments:nil];
}

@end
