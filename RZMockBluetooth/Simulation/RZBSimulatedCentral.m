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
#import "RZBSimulatedConnection.h"

@interface RZBSimulatedCentral ()

@property (strong, nonatomic, readonly) NSMutableArray *connections;
@property (strong, nonatomic, readonly) NSMutableArray *scannedDeviceUUIDs;

@property (strong, nonatomic) NSArray *servicesToScan;
@property (assign, nonatomic) BOOL isScanning;

@end

@implementation RZBSimulatedCentral

- (instancetype)initWithMockCentralManager:(RZBMockCentralManager *)centralManager
{
    NSParameterAssert(centralManager);
    self = [super init];
    if (self) {
        _connections = [NSMutableArray array];
        _scannedDeviceUUIDs = [NSMutableArray array];
        _mockCentralManager = centralManager;
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

- (void)triggerScanIfNeeded
{
    if (self.isScanning == NO) {
        return;
    }
    for (__weak RZBSimulatedConnection *connection in self.connections) {
        if ([connection isDiscoverableWithServices:self.servicesToScan] &&
            [self.scannedDeviceUUIDs containsObject:connection.identifier] == NO) {
            [connection.scanCallback dispatch:^(NSError *injectedError) {
                NSAssert(injectedError == nil, @"Can not inject errors into scans");
                if ([self.scannedDeviceUUIDs containsObject:connection.identifier] == NO && self.isScanning) {
                    [self.scannedDeviceUUIDs addObject:connection.identifier];
                    [self.mockCentralManager fakeScanPeripheralWithUUID:connection.peripheral.identifier
                                                                advInfo:connection.peripheralManager.advInfo
                                                                   RSSI:connection.RSSI];
                }
            }];
        }
    }
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    // Nothing to do here.
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    self.isScanning = YES;
    self.servicesToScan = services;
    [self triggerScanIfNeeded];
}

- (void)mockCentralManagerStopScan:(RZBMockCentralManager *)mockCentralManager
{
    self.isScanning = NO;
    self.servicesToScan = nil;
    [self.scannedDeviceUUIDs removeAllObjects];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options
{
    RZBSimulatedConnection *connection = [self connectionForIdentifier:peripheral.identifier];
    peripheral.mockDelegate = connection;
    [connection.connectCallback dispatch:^(NSError *injectedError) {
        [mockCentralManager fakeConnectPeripheralWithUUID:peripheral.identifier error:injectedError];
    }];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
    RZBSimulatedConnection *connection = [self connectionForIdentifier:peripheral.identifier];

    [connection.cancelConncetionCallback dispatch:^(NSError *injectedError) {
        [mockCentralManager fakeDisconnectPeripheralWithUUID:peripheral.identifier
                                                       error:injectedError];
    }];
}

@end
