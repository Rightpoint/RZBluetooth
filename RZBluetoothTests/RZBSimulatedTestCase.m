//
//  RZBProfileTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "NSRunLoop+RZBWaitFor.h"
#import "RZBCentralManager+Private.h"

@implementation RZBSimulatedTestCase

+ (void)load
{
    RZBEnableMock(YES);
}

+ (Class)simulatedDeviceClass
{
    return [RZBSimulatedDevice class];
}

- (void)waitForQueueFlush
{
    __block BOOL dispatchFlushed = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatchFlushed = YES;
    });
    BOOL ok = [[NSRunLoop currentRunLoop] rzb_waitWithTimeout:10.0 forCheck:^BOOL{
        return dispatchFlushed && self.centralManager.dispatch.dispatchCounter == 0;
    }];
    XCTAssertTrue(ok, @"Dispatch queue did not complete");
}

- (CBCentralManager<RZBMockedCentralManager> *)mockCentralManager
{
    CBCentralManager<RZBMockedCentralManager> *mockCentral = (id)self.centralManager.coreCentralManager;
    NSAssert([mockCentral conformsToProtocol:@protocol(RZBMockedCentralManager)], @"Invalid central manager");
    return mockCentral;
}

- (RZBPeripheral *)peripheral
{
    return [self.centralManager peripheralForUUID:self.connection.identifier];
}

- (void)configureCentralManager
{
    self.centralManager = [[RZBCentralManager alloc] init];
}

- (void)setUp
{
    [super setUp];
    [self configureCentralManager];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    NSUUID *identifier = [NSUUID UUID];
    self.device = [[self.class.simulatedDeviceClass alloc] initWithQueue:self.mockCentralManager.queue
                                                                 options:@{}];
    CBPeripheralManager<RZBMockedPeripheralManager> *peripheralManager = (id)self.device.peripheralManager;
    [peripheralManager fakeStateChange:CBPeripheralManagerStatePoweredOn];
    self.central = [[RZBSimulatedCentral alloc] initWithMockCentralManager:self.mockCentralManager];
    [self.central addSimulatedDeviceWithIdentifier:identifier
                                 peripheralManager:(id)self.device.peripheralManager];
    self.connection = [self.central connectionForIdentifier:identifier];
    [self waitForQueueFlush];
}

- (void)tearDown
{
    // All tests should end with no pending commands.
    RZBAssertCommandCount(0);
    self.centralManager = nil;
    self.device = nil;
    self.central = nil;
    [super tearDown];
}

@end
