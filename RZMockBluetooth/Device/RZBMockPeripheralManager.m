//
//  RZBSimulatedDevice.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockPeripheralManager.h"
#import "RZBSimulatedCallback.h"

@implementation RZBMockPeripheralManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = [NSUUID UUID];
        _advInfo = @{};
        _RSSI = @(-55);
        _readRequests = [NSMutableArray array];
        _writeRequests = [NSMutableArray array];
    }
    return self;
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

- (void)fakeReadRequest:(CBATTRequest *)request
{
    [self.readRequests addObject:request];
    [self.delegate peripheralManager:(id)self didReceiveReadRequest:request];
}

- (void)fakeWriteRequest:(CBATTRequest *)request type:(CBCharacteristicWriteType)type
{
    if (type == CBCharacteristicWriteWithResponse) {
        [self.writeRequests addObject:request];
    }
    [self.delegate peripheralManager:(id)self didReceiveWriteRequests:@[request]];

}

- (void)fakeNotifyState:(BOOL)enabled central:(CBCentral *)central characteristic:(CBMutableCharacteristic *)characteristic
{
    if (enabled) {
        [self.delegate peripheralManager:(id)self central:central didSubscribeToCharacteristic:(id)characteristic];
    }
    else {
        [self.delegate peripheralManager:(id)self central:central didUnsubscribeFromCharacteristic:(id)characteristic];
    }
}

@end
