//
//  RZBProfileTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBTestDefines.h"
#import "RZBluetooth/RZMockBluetooth.h"
#import "RZBSimulatedTestCase.h"
#import "NSRunLoop+RZBWaitFor.h"
#import "RZBluetooth/RZBCentralManager+Private.h"

@implementation RZBSimulatedTestCase

+ (void)setUp
{
    RZBEnableMock(YES);
    [super setUp];
}

+ (Class)simulatedDeviceClass
{
    return [RZBSimulatedDevice class];
}

- (void)waitForQueueFlush
{
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:10.0];
    // Wait for all of the connections to go idle
    while (!(self.central.idle && self.centralManager.dispatch.dispatchCounter == 0) && [endDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.00001]];
    }
    XCTAssertTrue([endDate timeIntervalSinceNow] > 0);
}

- (RZBMockCentralManager *)mockCentralManager
{
    RZBMockCentralManager *mockCentral = (id)self.centralManager.coreCentralManager;
    NSAssert([mockCentral isKindOfClass:[RZBMockCentralManager class]], @"Invalid central");
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
    RZBSetLogHandler(^(RZBLogLevel logLevel, NSString *format, va_list args) {
        if (logLevel != RZBLogLevelWriteCommandData && logLevel != RZBLogLevelDelegateValue) {
            NSLog(@"%@",  [[NSString alloc] initWithFormat:format arguments:args]);
        }
    });
    [super setUp];
    [self configureCentralManager];
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOn];

    NSUUID *identifier = [NSUUID UUID];
    self.device = [[self.class.simulatedDeviceClass alloc] initWithQueue:self.mockCentralManager.queue
                                                                 options:@{}];
    RZBMockPeripheralManager *peripheralManager = (id)self.device.peripheralManager;
    [peripheralManager fakeStateChange:RZBPeripheralManagerStatePoweredOn];

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
