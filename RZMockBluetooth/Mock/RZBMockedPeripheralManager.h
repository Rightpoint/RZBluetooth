//
//  RZBMockedPeripheralManager.h
//  RZBluetooth
//
//  Created by Brian King on 4/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@protocol RZBMockPeripheralManagerDelegate;


@protocol RZBMockedPeripheralManager <NSObject>

@property (weak, nonatomic) id<RZBMockPeripheralManagerDelegate> mockDelegate;
@property (copy, nonatomic) NSDictionary *advInfo;
@property (strong, nonatomic, readonly) NSMutableArray *services;

- (void)fakeStateChange:(CBPeripheralManagerState)state;
- (void)fakeReadRequest:(CBATTRequest *)request;
- (void)fakeWriteRequest:(CBATTRequest *)request;
- (void)fakeNotifyState:(BOOL)enabled central:(CBCentral *)central characteristic:(CBMutableCharacteristic *)characteristic;

@end

@protocol RZBMockPeripheralManagerDelegate <NSObject>

- (void)mockPeripheralManager:(id<RZBMockedPeripheralManager>)peripheralManager startAdvertising:(NSDictionary *)advertisementData;
- (void)mockPeripheralManagerStopAdvertising:(id<RZBMockedPeripheralManager>)peripheralManager;

- (void)mockPeripheralManager:(id<RZBMockedPeripheralManager>)peripheralManager setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central;
- (void)mockPeripheralManager:(id<RZBMockedPeripheralManager>)peripheralManager addService:(CBMutableService *)service;
- (void)mockPeripheralManager:(id<RZBMockedPeripheralManager>)peripheralManager removeService:(CBMutableService *)service;
- (void)mockPeripheralManagerRemoveAllServices:(id<RZBMockedPeripheralManager>)peripheralManager;

- (void)mockPeripheralManager:(id<RZBMockedPeripheralManager>)peripheralManager respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result;
- (BOOL)mockPeripheralManager:(id<RZBMockedPeripheralManager>)peripheralManager updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;


@end
