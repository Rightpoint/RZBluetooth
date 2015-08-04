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

@interface RZBSimulatedCentral () <RZBMockPeripheralDelegate>

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
        self.scanCallback = [RZBSimulatedCallback callback];
        self.connectCallback = [RZBSimulatedCallback callback];
        self.cancelConncetionCallback = [RZBSimulatedCallback callback];
        self.discoverServiceCallback = [RZBSimulatedCallback callback];
        self.discoverCharacteristicCallback = [RZBSimulatedCallback callback];
        self.readCharacteristicCallback = [RZBSimulatedCallback callback];
        self.writeCharacteristicCallback = [RZBSimulatedCallback callback];
        self.notifyCharacteristicCallback = [RZBSimulatedCallback callback];
    }
    return self;
}

- (BOOL)isDevice:(RZBMockPeripheralManager *)device discoverableWithServices:(NSArray *)services
{
    BOOL discoverable = (services == nil);
    for (CBService *service in device.services) {
        if (service.isPrimary && [services containsObject:service.UUID]) {
            discoverable = YES;
        }
    }
    return discoverable;
}

- (RZBMockPeripheralManager *)peripheralManagerWithIdentifier:(NSUUID *)identifier
{
    for (RZBMockPeripheralManager *device in self.devices) {
        if ([device.identifier isEqual:identifier]) {
            return device;
        }
    }
    return nil;
}

- (void)addSimulatedDevice:(RZBMockPeripheralManager *)device;
{
    [self.devices addObject:device];
}

- (void)removeSimulatedDevice:(RZBMockPeripheralManager *)device
{
    [self.devices removeObject:device];
}

- (CBATTRequest *)requestForCharacteristic:(CBCharacteristic *)characteristic
{
    CBATTRequest *request = [[CBATTRequest alloc] init];
    [request setValue:characteristic forKey:@"characteristic"];
    [request setValue:self forKey:@"central"];
    return request;
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    // Nothing to do here.
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    for (__weak RZBMockPeripheralManager *device in self.devices) {
        if ([self isDevice:device discoverableWithServices:services]) {
            [self.scanCallback dispatch:^(NSError *injectedError) {
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
    peripheral.mockDelegate = self;
    [self.connectCallback dispatch:^(NSError *injectedError) {
        [mockCentralManager fakeConnectPeripheralWithUUID:peripheral.identifier error:injectedError];
    }];
}

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
    [self.cancelConncetionCallback dispatch:^(NSError *injectedError) {
        [mockCentralManager fakeDisconnectPeripheralWithUUID:peripheral.identifier
                                                       error:injectedError];
    }];
}

#pragma mark - RZBMockPeripheralDelegate

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverServices:(NSArray *)serviceUUIDs
{
    RZBMockPeripheralManager *device = [self peripheralManagerWithIdentifier:peripheral.identifier];
    NSMutableArray *services = [NSMutableArray array];
    for (CBMutableService *service in device.services) {
        if ([serviceUUIDs containsObject:service.UUID]) {
            [services addObject:service];
        }
    }
    [self.discoverServiceCallback dispatch:^(NSError *injectedError) {
        [peripheral fakeDiscoverService:services error:injectedError];
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBMutableService *)service
{
    NSAssert([service isKindOfClass:[CBMutableService class]], @"");
    NSMutableArray *characteristics = [NSMutableArray array];
    for (CBMutableCharacteristic *characteristic in service.characteristics) {
        NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");
        if ([characteristicUUIDs containsObject:characteristic.UUID]) {
            [characteristics addObject:characteristic];
        }
    }
    [self.discoverCharacteristicCallback dispatch:^(NSError *injectedError) {

        [peripheral fakeDiscoverCharacteristics:characteristics forService:service error:injectedError];
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral readValueForCharacteristic:(CBMutableCharacteristic *)characteristic
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    RZBMockPeripheralManager *peripheralManager = [self peripheralManagerWithIdentifier:peripheral.identifier];
    [self.readCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            CBATTRequest *readRequest = [self requestForCharacteristic:characteristic];
            [peripheralManager fakeReadRequest:readRequest];
        }
        else {
            [peripheral fakeCharacteristic:characteristic updateValue:characteristic.value error:injectedError];
        }
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral writeValue:(NSData *)data forCharacteristic:(CBMutableCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    RZBMockPeripheralManager *peripheralManager = [self peripheralManagerWithIdentifier:peripheral.identifier];
    [self.writeCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            // FEATURE: The inbound data could be broken up into an array of write requests based on maximumUpdateValueLength.
            CBATTRequest *writeRequest = [self requestForCharacteristic:characteristic];
            writeRequest.value = data;
            [peripheralManager fakeWriteRequest:writeRequest type:type];
        }
        else if (type == CBCharacteristicWriteWithResponse) {
            [peripheral fakeCharacteristic:characteristic writeResponseWithError:injectedError];
        }
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBMutableCharacteristic *)characteristic
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    RZBMockPeripheralManager *peripheralManager = [self peripheralManagerWithIdentifier:peripheral.identifier];
    [self.notifyCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            [peripheralManager fakeNotifyState:enabled central:(id)self characteristic:(id)characteristic];
        }
        else {
            [peripheral fakeCharacteristic:characteristic notify:enabled error:injectedError];
        }
    }];
}

- (void)mockPeripheralReadRSSI:(RZBMockPeripheral *)peripheral
{

}

@end
