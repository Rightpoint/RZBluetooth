//
//  RZBProfileTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "NSRunLoop+RZBWaitFor.h"

@implementation RZBSimulatedTestCase

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

- (RZBMockCentralManager *)mockCentralManager
{
    return self.centralManager.mockCentralManager;
}

- (CBPeripheral *)peripheral
{
    return [self.centralManager peripheralForUUID:self.device.identifier];
}

- (void)setUp
{
    [super setUp];
    self.centralManager = [[RZBTestableCentralManager alloc] init];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    self.device = [[self.class.simulatedDeviceClass alloc] initWithQueue:self.mockCentralManager.queue
                                                    options:@{}
                                     peripheralManagerClass:[RZBMockPeripheralManager class]];
    [self.centralManager.simulatedCentral addSimulatedDeviceWithIdentifier:self.device.identifier
                                                         peripheralManager:(id)self.device.peripheralManager];
    self.connection = [self.centralManager.simulatedCentral connectionForIdentifier:self.device.identifier];
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
