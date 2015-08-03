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

@interface RZBSimulatedCentral ()

@property (strong, nonatomic) NSArray *devices;

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
    self.devices = [self.devices ?:@[] arrayByAddingObject:device];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    // Nothing to do here.
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    for (RZBSimulatedDevice *device in self.devices) {
        if ([self isDevice:device discoverableWithServices:services]) {
            if (device.onScan) {
                device.onScan(device, mockCentralManager);
            }
            else {
                [mockCentralManager fakeScanPeripheralWithUUID:device.identifier
                                                       advInfo:device.advInfo
                                                          RSSI:device.RSSI];
            }
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
    if (device.onConnect) {
        device.onConnect(device, mockCentralManager);
    }
    else {
        [mockCentralManager fakeConnectPeripheralWithUUID:peripheral.identifier error:nil];
    }
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
    RZBSimulatedDevice *device = [self deviceWithIdentifier:peripheral.identifier];
    if (device.onCancelConnection) {
        device.onCancelConnection(device, mockCentralManager);
    }
    else {
        [mockCentralManager fakeDisconnectPeripheralWithUUID:peripheral.identifier error:nil];
    }
}

@end
