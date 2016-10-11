//
//  RZBSimulatedCentral.m
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCentral.h"
#import "RZBMockPeripheralManager.h"
#import "RZBMockPeripheral.h"
#import "RZBSimulatedCallback.h"
#import "RZBSimulatedConnection+Private.h"

@interface RZBSimulatedCentral () <RZBMockCentralManagerDelegate>

@property (strong, nonatomic) NSArray *servicesToScan;

@end

@implementation RZBSimulatedCentral

- (instancetype)initWithMockCentralManager:(RZBMockCentralManager *)mockCentralManager
{
    NSParameterAssert(mockCentralManager);
    NSAssert(_mockCentralManager.mockDelegate == nil, @"Can only attach one simulated central to a mocked central manager.");
    self = [super init];
    if (self) {
        _connections = [NSMutableArray array];
        _mockCentralManager = mockCentralManager;
        _mockCentralManager.mockDelegate = self;
    }
    return self;
}

- (void)dealloc
{
    // Ensure that any callbacks on the connection are canceled
    for (RZBSimulatedConnection *connection in self.connections) {
        [connection cancelSimulatedCallbacks];
    }
}

- (RZBSimulatedConnection *)connectionForIdentifier:(NSUUID *)identifier
{
    for (RZBSimulatedConnection *connection in self.connections) {
        if ([connection.identifier isEqual:identifier]) {
            return connection;
        }
    }
    return nil;
}

- (BOOL)idle
{
    BOOL idle = YES;
    for (RZBSimulatedConnection *connection in self.connections) {
        if (!connection.idle) {
            idle = NO;
        }
    }
    return idle;
}

- (NSSet *)dispatchQueues
{
    NSMutableSet *queues = [NSMutableSet setWithObject:self.mockCentralManager.queue];
    for (RZBSimulatedConnection *connection in self.connections) {
        dispatch_queue_t queue = connection.peripheralManager.queue;
        [queues addObject:queue];
    }
    return queues;
}

- (BOOL)waitForDispatchFlush:(NSTimeInterval)timeout
{
    // Send a dispatch barrier over all of the queue's to make sure anything in the queue is flushed
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    NSSet *queues = self.dispatchQueues;

    __block BOOL flushCount = 0;
    for (dispatch_queue_t queue in queues) {
        dispatch_barrier_async(queue, ^{
            // Process all of the sources in the current threads runloop.
            // When there's nothing left to process, continue.
            while ( CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true) == kCFRunLoopRunHandledSource ) {}
            flushCount++;
        });
    }
    while(flushCount < queues.count && [endDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
    return [endDate timeIntervalSinceNow] > 0;
}

- (BOOL)waitForIdleWithTimeout:(NSTimeInterval)timeout
{
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    // Wait for all of the connections to go idle
    while (!self.idle && [endDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
    // Flush all of the dispatch queues if there's still remaining time.
    NSTimeInterval remainingTimeout = [endDate timeIntervalSinceNow];
    if (remainingTimeout > 0 && [self waitForDispatchFlush:[endDate timeIntervalSinceNow]]) {
        // Double check that all of the connections are idle. If the dispatch flush caused a callback to go active
        // recurse and wait for things to go idle again.
        return self.idle ? YES : [self waitForIdleWithTimeout:remainingTimeout];
    }
    else {
        return NO;
    }
}

- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralManager:(RZBMockPeripheralManager *)peripheralManager
{
    NSAssert([self connectionForIdentifier:peripheralUUID] == nil, @"%@ is already registered", peripheralUUID);
    RZBSimulatedConnection *connection = [[RZBSimulatedConnection alloc] initWithIdentifier:peripheralUUID
                                                                          peripheralManager:peripheralManager
                                                                                    central:self];
    [self.connections addObject:connection];
}

- (void)removeSimulatedDevice:(NSUUID *)peripheralUUID
{
    RZBSimulatedConnection *connection = [self connectionForIdentifier:peripheralUUID];
    [self.connections removeObject:connection];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    // Nothing to do here.
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    NSParameterAssert(mockCentralManager);
    typeof(self) weakSelf = self;

    self.servicesToScan = services;
    for (__weak RZBSimulatedConnection *connection in self.connections) {
        if ([connection isDiscoverableWithServices:self.servicesToScan]) {
            [connection.scanCallback dispatch:^(NSError *injectedError) {
                NSAssert(injectedError == nil, @"Can not inject errors into scans");
                [weakSelf.mockCentralManager fakeScanPeripheralWithUUID:connection.peripheral.identifier
                                                                advInfo:connection.peripheralManager.advInfo
                                                                   RSSI:connection.RSSI];
            }];
        }
    }
}

- (void)mockCentralManagerStopScan:(RZBMockCentralManager *)mockCentralManager
{
    NSParameterAssert(mockCentralManager);
    self.servicesToScan = nil;
    for (RZBSimulatedConnection *connection in self.connections) {
        [connection.scanCallback cancel];
    }
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options
{
    NSParameterAssert(mockCentralManager);
    NSParameterAssert(peripheral);
    RZBSimulatedConnection *connection = [self connectionForIdentifier:peripheral.identifier];
    NSAssert(connection != nil, @"Attempt to connect to an unknown peripheral %@", peripheral.identifier);
    peripheral.mockDelegate = connection;
    [connection.connectCallback dispatch:^(NSError *injectedError) {
        [mockCentralManager fakeConnectPeripheralWithUUID:peripheral.identifier error:injectedError];
    }];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
    NSParameterAssert(mockCentralManager);
    NSParameterAssert(peripheral);
    RZBSimulatedConnection *connection = [self connectionForIdentifier:peripheral.identifier];
    NSAssert(connection != nil, @"Attempt to disconnect to an unknown peripheral %@", peripheral.identifier);

    peripheral.mockDelegate = nil;

    [connection disconnect];
}

@end
