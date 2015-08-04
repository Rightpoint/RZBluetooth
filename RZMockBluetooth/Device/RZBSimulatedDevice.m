//
//  RZBSimulatedDevice.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedDevice.h"
#import "RZBSimulatedCallback.h"

#import "RZBMockService.h"
#import "RZBMockCharacteristic.h"

@implementation RZBSimulatedDevice

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = [NSUUID UUID];
        _advInfo = @{};
        _RSSI = @(-55);
        _readRequests = [NSMutableArray array];
        _writeRequests = [NSMutableArray array];
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

- (CBATTRequest *)requestForCharacteristic:(RZBMockCharacteristic *)characteristic
{
    CBATTRequest *writeRequest = [[CBATTRequest alloc] init];
    [writeRequest setValue:characteristic forKey:@"characteristic"];
    return writeRequest;
}

- (NSError *)errorForResult:(CBATTError)result
{
    return result == CBATTErrorSuccess ? nil : [NSError errorWithDomain:CBErrorDomain code:result userInfo:@{}];
}

- (void)respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result
{
    NSError *error = [self errorForResult:result];
    if ([self.readRequests containsObject:request]) {
        [self.peripheral fakeCharacteristic:(id)request.characteristic updateValue:request.value error:error];
    }
    else if ([self.writeRequests containsObject:request]) {
        [self.peripheral fakeCharacteristic:(id)request.characteristic writeResponseWithError:error];
    }
}

- (BOOL)updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals
{
    [self.peripheral fakeCharacteristic:(id)characteristic updateValue:value error:nil];
    return YES;
}


#pragma mark - RZBMockPeripheralDelegate

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverServices:(NSArray *)serviceUUIDs
{
    NSMutableArray *services = [NSMutableArray array];
    for (RZBMockService *service in self.services) {
        if ([serviceUUIDs containsObject:service.UUID]) {
            [services addObject:service];
        }
    }
    [self.discoverServiceCallback dispatch:^(NSError *injectedError) {
        [peripheral fakeDiscoverService:services error:injectedError];
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(RZBMockService *)service
{
    NSMutableArray *characteristics = [NSMutableArray array];
    for (RZBMockCharacteristic *characteristic in service.characteristics) {
        if ([characteristicUUIDs containsObject:characteristic.UUID]) {
            [characteristics addObject:characteristic];
        }
    }
    [self.discoverCharacteristicCallback dispatch:^(NSError *injectedError) {
        [peripheral fakeDiscoverCharacteristics:characteristics forService:service error:injectedError];
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral readValueForCharacteristic:(RZBMockCharacteristic *)characteristic
{
    [self.readCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            CBATTRequest *readRequest = [self requestForCharacteristic:characteristic];
            [self.readRequests addObject:readRequest];
            [self.delegate peripheralManager:(id)self didReceiveReadRequest:readRequest];
        }
        else {
            [peripheral fakeCharacteristic:characteristic updateValue:characteristic.value error:injectedError];
        }
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral writeValue:(NSData *)data forCharacteristic:(RZBMockCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [self.writeCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            CBATTRequest *writeRequest = [self requestForCharacteristic:characteristic];
            writeRequest.value = data;
            if (type == CBCharacteristicWriteWithResponse) {
                [self.writeRequests addObject:writeRequest];
            }
            [self.delegate peripheralManager:(id)self didReceiveWriteRequests:@[writeRequest]];
        }
        else if (type == CBCharacteristicWriteWithResponse) {
            [peripheral fakeCharacteristic:characteristic writeResponseWithError:injectedError];
        }
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(RZBMockCharacteristic *)characteristic
{
    [self.notifyCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            if (enabled) {
                [self.delegate peripheralManager:(id)self central:(id)self didSubscribeToCharacteristic:(id)characteristic];
            }
            else {
                [self.delegate peripheralManager:(id)self central:(id)self didUnsubscribeFromCharacteristic:(id)characteristic];
            }
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
