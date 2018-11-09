//
//  RZBSimulatedDevice.m
//  RZBluetooth
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockPeripheralManager.h"
#import "RZBSimulatedCallback.h"

@implementation RZBMockPeripheralManager

- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue
{
    return [self initWithDelegate:delegate queue:queue options:@{}];
}

- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        _services = [NSMutableArray array];
        _delegate = delegate;
        _options = options;
        _queue = queue ?: dispatch_get_main_queue();
    }
    return self;
}

- (void)startAdvertising:(NSDictionary *)advertisementData
{
    _isAdvertising = YES;
    [self.mockDelegate mockPeripheralManager:self startAdvertising:advertisementData];
}

- (void)stopAdvertising
{
    _isAdvertising = NO;
    [self.mockDelegate mockPeripheralManagerStopAdvertising:self];
}

- (void)setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central
{
    [self.mockDelegate mockPeripheralManager:self setDesiredConnectionLatency:latency forCentral:central];
}

- (void)addService:(CBMutableService *)service
{
    @synchronized (self.services) {
        [self.services addObject:service];
    }
    [self.mockDelegate mockPeripheralManager:self addService:service];
}

- (void)removeService:(CBMutableService *)service
{
    @synchronized (self.services) {
        [self.services removeObject:service];
    }
    [self.mockDelegate mockPeripheralManager:self removeService:service];
}

- (void)removeAllServices
{
    @synchronized (self.services) {
        [self.services removeAllObjects];
    }
    [self.mockDelegate mockPeripheralManagerRemoveAllServices:self];
}

- (void)respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result
{
    [self.mockDelegate mockPeripheralManager:self respondToRequest:request withResult:result];
}

- (BOOL)updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals
{
    return [self.mockDelegate mockPeripheralManager:self updateValue:value forCharacteristic:characteristic onSubscribedCentrals:centrals];
}

- (void)performFakeAction:(void(^)(void))block
{
    @synchronized (self) {
        self.fakeActionCount += 1;
    }
    dispatch_async(self.queue, ^{
        block();
        @synchronized (self) {
            self.fakeActionCount -= 1;
        }
    });
}

- (void)fakeStateChange:(RZBPeripheralManagerState)state
{
    [self performFakeAction:^{
        self.state = state;
        [self.delegate peripheralManagerDidUpdateState:(id)self];
    }];
}

- (void)fakeReadRequest:(CBATTRequest *)request
{
    [self performFakeAction:^{
        [self.delegate peripheralManager:(id)self didReceiveReadRequest:request];
    }];
}

- (void)fakeWriteRequest:(CBATTRequest *)request
{
    [self performFakeAction:^{
        [self.delegate peripheralManager:(id)self didReceiveWriteRequests:@[request]];
    }];
}

- (void)fakeNotifyState:(BOOL)enabled central:(CBCentral *)central characteristic:(CBMutableCharacteristic *)characteristic
{
    [self performFakeAction:^{
        if (enabled) {
            [self.delegate peripheralManager:(id)self central:central didSubscribeToCharacteristic:(id)characteristic];
        }
        else {
            [self.delegate peripheralManager:(id)self central:central didUnsubscribeFromCharacteristic:(id)characteristic];
        }
    }];
}

@end
