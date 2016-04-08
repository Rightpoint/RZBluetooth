//
//  RZBSimulatedDevice.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "RZBMockedPeripheralManager.h"

/**
 * Mock API for CBPeripheralManager. This is not a direct subclass of CBPeripheralManager
 * because not all of the things can be controlled (like peripheralManagerDidUpdateState: signaling)
 */
@interface RZBMockPeripheralManager : NSObject <RZBMockedPeripheralManager>

- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue;
- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options;

@property (weak, nonatomic, readonly) id<CBPeripheralManagerDelegate>delegate;
@property (readonly) CBPeripheralManagerState state;
@property (readonly) BOOL isAdvertising;

- (void)startAdvertising:(NSDictionary *)advertisementData;
- (void)stopAdvertising;
- (void)setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central;
- (void)addService:(CBMutableService *)service;
- (void)removeService:(CBMutableService *)service;
- (void)removeAllServices;

@property (copy, nonatomic, readonly) NSDictionary *options;
@property (copy, nonatomic, readonly) dispatch_queue_t queue;

- (void)respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result;
- (BOOL)updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;

@end

