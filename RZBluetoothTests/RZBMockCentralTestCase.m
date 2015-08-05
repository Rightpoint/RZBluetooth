//
//  RZBMockCentralTestCase.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralTestCase.h"

@implementation RZBMockCentralTestCase

- (void)waitForQueueFlush
{
    XCTestExpectation *e = [self expectationWithDescription:@"Queue Flush"];
    [self waitForDispatch:self.centralManager.dispatch expectation:e];
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Queue did not flush - %@", error);
        }
    }];
}

- (RZBMockCentralManager *)mockCentralManager
{
    return self.centralManager.mockCentralManager;
}

- (void)setUp
{
    [super setUp];
    self.centralManager = [[RZBTestableCentralManager alloc] init];
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

    RZBMockPeripheral *p = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(connectPeripheral:options:)], p);

    // Fake the connection, and ensure the discover commands occurred.
    [self.mockCentralManager fakeConnectPeripheralWithUUID:peripheralUUID error:nil];
    [self waitForQueueFlush];
}

- (void)ensureAndCompleteDiscoveryOfService:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID
{
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverServiceCommand, self.class.pUUIDPath, YES);

    RZBMockPeripheral *p = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverServices:)], @[serviceUUID]);

    // Fake the service discovery
    [p fakeDiscoverServicesWithUUIDs:@[self.class.sUUID] error:nil];
    [self waitForQueueFlush];
}

- (void)ensureAndCompleteDiscoveryOfCharacteristic:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID
{
    [self waitForQueueFlush];
    RZBAssertHasCommand(RZBDiscoverCharacteristicCommand, RZBUUIDP(peripheralUUID, serviceUUID), YES);

    RZBMockPeripheral *p = [self.mockCentralManager peripheralForUUID:peripheralUUID];
    CBMutableService *s = [p serviceForUUID:serviceUUID];
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:0 forSelector:@selector(discoverCharacteristics:forService:)], @[characteristicUUID]);
    XCTAssertEqualObjects([self.invocationLog argumentAtIndex:1 forSelector:@selector(discoverCharacteristics:forService:)], s);

    [p fakeDiscoverCharacteristicsWithUUIDs:@[characteristicUUID] forService:s error:nil];

    [self waitForQueueFlush];
}

- (void)triggerThreeCommandsAndStoreErrorsIn:(NSMutableArray *)errors
{
    RZBMockPeripheral *p = (id)[self.centralManager peripheralForUUID:self.class.pUUID];
    [p rzb_readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *peripheral, NSError *error) {
                           XCTAssertNotNil(error);
                           [errors addObject:error];
                       }];
    [p rzb_readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *peripheral, NSError *error) {
                           XCTAssertNotNil(error);
                           [errors addObject:error];
                       }];
    [p rzb_readCharacteristicUUID:self.class.cUUID
                      serviceUUID:self.class.sUUID
                       completion:^(CBCharacteristic *peripheral, NSError *error) {
                           XCTAssertNotNil(error);
                           [errors addObject:error];
                       }];
    [self waitForQueueFlush];
}

- (void)setupConnectedPeripheral
{
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    [self.centralManager connectToPeripheralUUID:self.class.pUUID completion:^(CBPeripheral *peripheral, NSError *error) {}];
    [self ensureAndCompleteConnectionTo:self.class.pUUID];
}

#pragma mark Delegate -> Invocation Log.

// Small macro to transform the delegate method to the originating method.
#define C_CMD NSSelectorFromString([NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString:@"mockCentralManager:" withString:@""])
#define P_CMD NSSelectorFromString([NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString:@"mockPeripheral:" withString:@""])

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;
{
    for (NSUUID *identifier in identifiers) {
        RZBMockPeripheral *p = [mockCentralManager peripheralForUUID:identifier];
        p.mockDelegate = self;
    }
    [self.invocationLog logSelector:C_CMD arguments:identifiers];
}
- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    [self.invocationLog logSelector:C_CMD arguments:services, options];
}

- (void)mockCentralManagerStopScan:(RZBMockCentralManager *)mockCentralManager
{
    [self.invocationLog logSelector:@selector(stopScan) arguments:nil];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options
{
    [self.invocationLog logSelector:C_CMD arguments:peripheral, options];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
    [self.invocationLog logSelector:C_CMD arguments:peripheral];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverServices:(NSArray *)serviceUUIDs
{
    [self.invocationLog logSelector:P_CMD arguments:serviceUUIDs];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service
{
    [self.invocationLog logSelector:P_CMD arguments:characteristicUUIDs, service];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral readValueForCharacteristic:(CBCharacteristic *)characteristic
{
    [self.invocationLog logSelector:P_CMD arguments:characteristic];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [self.invocationLog logSelector:P_CMD arguments:data, characteristic, @(type)];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic
{
    [self.invocationLog logSelector:P_CMD arguments:@(enabled), characteristic];
}

- (void)mockPeripheralReadRSSI:(RZBMockPeripheral *)peripheral
{
    [self.invocationLog logSelector:@selector(readRSSI) arguments:nil];
}

@end
