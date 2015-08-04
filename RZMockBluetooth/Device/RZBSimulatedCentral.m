//
//  RZBSimulatedCentral.m
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCentral.h"
#import "RZBSimulatedDevice.h"
#import "RZBMockPeripheral.h"
#import "RZBSimulatedCallback.h"

@interface RZBSimulatedCentral ()

@property (strong, nonatomic) NSMutableArray *devices;

@end

@implementation RZBSimulatedCentral

+ (RZBSimulatedCentral *)shared
{
    static RZBSimulatedCentral *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RZBSimulatedCentral alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.devices = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isDevice:(RZBSimulatedDevice *)device discoverableWithServices:(NSArray *)services
{
    BOOL discoverable = (services == nil);
    for (CBService *service in device.services) {
        if (service.isPrimary && [services containsObject:service.UUID]) {
            discoverable = YES;
        }
    }
    return discoverable;
}

- (RZBSimulatedDevice *)deviceWithIdentifier:(NSUUID *)identifier
{
    for (RZBSimulatedDevice *device in self.devices) {
        if ([device.identifier isEqual:identifier]) {
            return device;
        }
    }
    return nil;
}

- (void)addSimulatedDevice:(RZBSimulatedDevice *)device;
{
    [self.devices addObject:device];
}

- (void)removeSimulatedDevice:(RZBSimulatedDevice *)device
{
    [self.devices removeObject:device];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    // Nothing to do here.
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    for (__weak RZBSimulatedDevice *device in self.devices) {
        if ([self isDevice:device discoverableWithServices:services]) {
            [device.scanCallback dispatch:^(NSError *injectedError) {
                NSAssert(injectedError == nil, @"Can not inject errors into scans");
                [mockCentralManager fakeScanPeripheralWithUUID:device.identifier
                                                       advInfo:device.advInfo
                                                          RSSI:device.RSSI];
            }];
        }
    }
}

- (void)mockCentralManagerStopScan:(RZBMockCentralManager *)mockCentralManager
{
    // Nothing to do here. When the device has a 'discover delay' those will need to be cancelled.
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options
{
    RZBSimulatedDevice *device = [self deviceWithIdentifier:peripheral.identifier];
    peripheral.mockDelegate = device;
    [device.connectCallback dispatch:^(NSError *injectedError) {
        [mockCentralManager fakeConnectPeripheralWithUUID:peripheral.identifier error:injectedError];
    }];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
    RZBSimulatedDevice *device = [self deviceWithIdentifier:peripheral.identifier];
    [device.cancelConncetionCallback dispatch:^(NSError *injectedError) {
        [mockCentralManager fakeDisconnectPeripheralWithUUID:peripheral.identifier
                                                       error:injectedError];
    }];
}

@end
