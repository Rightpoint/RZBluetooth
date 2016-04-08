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
    CBCentralManager<RZBMockedCentralManager> *mockCentral = (id)self.centralManager.centralManager;
    NSAssert([mockCentral conformsToProtocol:@protocol(RZBMockedCentralManager)], @"Invalid central manager");
    return mockCentral;
}

- (RZBPeripheral *)peripheral
{
    return [self.centralManager peripheralForUUID:self.device.identifier];
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
    self.device = [[self.class.simulatedDeviceClass alloc] initMockWithIdentifier:[NSUUID UUID]
                                                                            queue:self.mockCentralManager.queue
                                                                          options:@{}];
    self.central = [[RZBSimulatedCentral alloc] initWithMockCentralManager:self.mockCentralManager];
    [self.central addSimulatedDeviceWithIdentifier:self.device.identifier
                                 peripheralManager:(id)self.device.peripheralManager];
    self.connection = [self.central connectionForIdentifier:self.device.identifier];
}

- (void)tearDown
{
    // All tests should end with no pending commands.
    RZBAssertCommandCount(0);
    self.centralManager = nil;
    self.device = nil;
    [super tearDown];
}

@end
