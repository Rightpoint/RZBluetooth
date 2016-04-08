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

- (void)fakeReadRequest:(CBATTRequest *)request;
- (void)fakeWriteRequest:(CBATTRequest *)request;
- (void)fakeNotifyState:(BOOL)enabled central:(CBCentral *)central characteristic:(CBMutableCharacteristic *)characteristic;

@end

@protocol RZBMockPeripheralManagerDelegate <NSObject>

- (void)mockPeripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager startAdvertising:(NSDictionary *)advertisementData;
- (void)mockPeripheralManagerStopAdvertising:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager;

- (void)mockPeripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central;
- (void)mockPeripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager addService:(CBMutableService *)service;
- (void)mockPeripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager removeService:(CBMutableService *)service;
- (void)mockPeripheralManagerRemoveAllServices:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager;

- (void)mockPeripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result;
- (BOOL)mockPeripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;


@end
