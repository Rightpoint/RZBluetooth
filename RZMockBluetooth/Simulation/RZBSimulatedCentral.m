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
        [connection reset];
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
    if (self.mockCentralManager.fakeActionCount > 0) {
        idle = NO;
    }
    return idle;
}

- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralManager:(RZBMockPeripheralManager *)peripheralManager
{
    [self addSimulatedDeviceWithIdentifier:peripheralUUID peripheralName:@"Simulated Device" peripheralManager:peripheralManager];
}

- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralName:(NSString *)name peripheralManager:(RZBMockPeripheralManager *)peripheralManager
{
    NSAssert([self connectionForIdentifier:peripheralUUID] == nil, @"%@ is already registered", peripheralUUID);
    RZBSimulatedConnection *connection = [[RZBSimulatedConnection alloc] initWithIdentifier:peripheralUUID
                                                                             peripheralName:name
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

- (NSArray *)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs
{
    NSParameterAssert(mockCentralManager);
    NSMutableArray *connectedPeripherals = [NSMutableArray array];
    for (RZBSimulatedConnection *connection in self.connections) {
        for (CBMutableService* service in connection.peripheral.services) {
            if ([serviceUUIDs containsObject:service.UUID]) {
                [connectedPeripherals addObject:connection.peripheral];
                break; // exit inner loop so peripheral is only added once.
            }
        }
    }
    return connectedPeripherals;
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
