//
//  RZBSimulatedCentral.m
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCentral.h"
#import "RZBSimulatedCallback.h"
#import "RZBSimulatedConnection+Private.h"

@interface RZBSimulatedCentral () <RZBMockCentralManagerDelegate>

@property (strong, nonatomic, readonly) NSMutableArray *connections;

@property (strong, nonatomic) NSArray *servicesToScan;

@end

@implementation RZBSimulatedCentral

- (instancetype)initWithMockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager
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

- (RZBSimulatedConnection *)connectionForIdentifier:(NSUUID *)identifier
{
    for (RZBSimulatedConnection *connection in self.connections) {
        if ([connection.identifier isEqual:identifier]) {
            return connection;
        }
    }
    return nil;
}

- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralManager:(id<RZBMockedPeripheralManager>)peripheralManager
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

- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    // Nothing to do here.
}

- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    NSParameterAssert(mockCentralManager);
    self.servicesToScan = services;
    for (__weak RZBSimulatedConnection *connection in self.connections) {
        if ([connection isDiscoverableWithServices:self.servicesToScan]) {
            [connection.scanCallback dispatch:^(NSError *injectedError) {
                NSAssert(injectedError == nil, @"Can not inject errors into scans");
                [self.mockCentralManager fakeScanPeripheralWithUUID:connection.peripheral.identifier
                                                            advInfo:connection.peripheralManager.advInfo
                                                               RSSI:connection.RSSI];
            }];
        }
    }
}

- (void)mockCentralManagerStopScan:(id<RZBMockedCentralManager>)mockCentralManager
{
    NSParameterAssert(mockCentralManager);
    self.servicesToScan = nil;
    for (RZBSimulatedConnection *connection in self.connections) {
        [connection.scanCallback cancel];
    }
}

- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager connectPeripheral:(id<RZBMockedPeripheral>)peripheral options:(NSDictionary *)options
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

- (void)mockCentralManager:(id<RZBMockedCentralManager>)mockCentralManager cancelPeripheralConnection:(id<RZBMockedPeripheral>)peripheral
{
    NSParameterAssert(mockCentralManager);
    NSParameterAssert(peripheral);
    RZBSimulatedConnection *connection = [self connectionForIdentifier:peripheral.identifier];
    NSAssert(connection != nil, @"Attempt to disconnect to an unknown peripheral %@", peripheral.identifier);

    peripheral.mockDelegate = nil;

    [connection disconnect];
}

@end
