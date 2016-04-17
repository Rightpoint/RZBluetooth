//
//  RZBMockCentralTestCase.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralTestCase.h"
#import "NSRunLoop+RZBWaitFor.h"

@implementation RZBMockCentralTestCase

- (void)waitForQueueFlush
{
    BOOL done = [[NSRunLoop currentRunLoop] rzb_waitWithTimeout:2.0 forCheck:^BOOL{
        return self.centralManager.dispatch.dispatchCounter == 0;
    }];
    XCTAssert(done);
}

- (id<RZBMockedCentralManager>)mockCentralManager
{
    id<RZBMockedCentralManager>mockCentral = (id)self.centralManager.coreCentralManager;
    NSAssert([mockCentral conformsToProtocol:@protocol(RZBMockedCentralManager)], @"Invalid central");
    return mockCentral;
}

- (void)setUp
{
    [super setUp];
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

    id<RZBMockedPeripheral>mockPeripheral = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(connectPeripheral:options:)], mockPeripheral);

    // Fake the connection, and ensure the discover commands occurred.
    [self.mockCentralManager fakeConnectPeripheralWithUUID:peripheralUUID error:nil];
    [self waitForQueueFlush];
}

- (void)ensureAndCompleteDiscoveryOfService:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID
{
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverServiceCommand, self.class.pUUIDPath, YES);

    id<RZBMockedPeripheral>mockPeripheral = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[serviceUUID]);

    // Fake the service discovery
    [mockPeripheral fakeDiscoverServicesWithUUIDs:@[self.class.sUUID] error:nil];
    [self waitForQueueFlush];
}

- (void)ensureAndCompleteDiscoveryOfCharacteristic:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID
{
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverCharacteristicCommand, RZBUUIDP(peripheralUUID, serviceUUID), YES);

    id<RZBMockedPeripheral>mockPeripheral = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    CBMutableService *s = [mockPeripheral serviceForUUID:serviceUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[characteristicUUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);

    [mockPeripheral fakeDiscoverCharacteristicsWithUUIDs:@[characteristicUUID] forService:s error:nil];

    [self waitForQueueFlush];
}

- (void)triggerThreeCommandsAndStoreErrorsIn:(NSMutableArray *)errors
{
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];
    [peripheral readCharacteristicUUID:self.class.cUUID
                           serviceUUID:self.class.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [peripheral readCharacteristicUUID:self.class.cUUID
                           serviceUUID:self.class.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [peripheral readCharacteristicUUID:self.class.cUUID
                           serviceUUID:self.class.sUUID
                            completion:^(CBCharacteristic *characteristic, NSError *error) {
                                XCTAssertNotNil(error);
                                [errors addObject:error];
                            }];
    [self waitForQueueFlush];
}

- (void)setupConnectedPeripheral
{
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.class.pUUID];

    [peripheral connectWithCompletion:^(NSError *error) {}];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];
}

#pragma mark Delegate -> Invocation Log.

// Small macro to transform the delegate method to the originating method.
#define C_CMD NSSelectorFromString([NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString:@"mockCentralManager:" withString:@""])
#define P_CMD NSSelectorFromString([NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString:@"mockPeripheral:" withString:@""])

- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;
{
    for (NSUUID *identifier in identifiers) {
        id<RZBMockedPeripheral>mockPeripheral = [mockCentralManager peripheralForUUID:identifier];
        mockPeripheral.mockDelegate = self;
    }
    [self.invocationLog logSelector:C_CMD arguments:identifiers];
}
- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    [self.invocationLog logSelector:C_CMD arguments:services, options];
}

- (void)mockCentralManagerStopScan:(id<RZBMockedCentralManager>)mockCentralManager
{
    [self.invocationLog logSelector:@selector(stopScan) arguments:nil];
}

- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager connectPeripheral:(id<RZBMockedPeripheral>)mockPeripheral options:(NSDictionary *)options
{
    [self.invocationLog logSelector:C_CMD arguments:mockPeripheral, options];
}

- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager cancelPeripheralConnection:(id<RZBMockedPeripheral>)mockPeripheral
{
    [self.invocationLog logSelector:C_CMD arguments:mockPeripheral];
}

- (void)mockPeripheral:(id<RZBMockedPeripheral>)mockPeripheral discoverServices:(NSArray *)serviceUUIDs
{
    [self.invocationLog logSelector:P_CMD arguments:serviceUUIDs];
}

- (void)mockPeripheral:(id<RZBMockedPeripheral>)mockPeripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service
{
    [self.invocationLog logSelector:P_CMD arguments:characteristicUUIDs, service];
}

- (void)mockPeripheral:(id<RZBMockedPeripheral>)mockPeripheral readValueForCharacteristic:(CBCharacteristic *)characteristic
{
    [self.invocationLog logSelector:P_CMD arguments:characteristic];
}

- (void)mockPeripheral:(id<RZBMockedPeripheral>)mockPeripheral writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [self.invocationLog logSelector:P_CMD arguments:data, characteristic, @(type)];
}

- (void)mockPeripheral:(id<RZBMockedPeripheral>)mockPeripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic
{
    [self.invocationLog logSelector:P_CMD arguments:@(enabled), characteristic];
}

- (void)mockPeripheralReadRSSI:(id<RZBMockedPeripheral>)mockPeripheral
{
    [self.invocationLog logSelector:@selector(readRSSI) arguments:nil];
}

@end
