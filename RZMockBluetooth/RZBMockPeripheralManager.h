//
//  RZBSimulatedDevice.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RZBMockPeripheral.h"

@class RZBMockCentralManager;
@class RZBMockPeripheralManager;
@class RZBSimulatedCallback;
@protocol RZBMockPeripheralManagerDelegate;

typedef NSData*(^RZBReadAction)(void);
typedef void(^RZBWriteAction)(NSData *data);
typedef void(^RZBNotifyAction)(BOOL isNotifying);

@interface RZBMockPeripheralManager : NSObject

- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue;
- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options;

@property (weak, nonatomic, readonly) id<CBPeripheralManagerDelegate>delegate;
@property(readonly) CBPeripheralManagerState state;
@property(readonly) BOOL isAdvertising;

- (void)startAdvertising:(NSDictionary *)advertisementData;
- (void)stopAdvertising;
- (void)setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central;
- (void)addService:(CBMutableService *)service;
- (void)removeService:(CBMutableService *)service;
- (void)removeAllServices;


@property (weak, nonatomic) id<RZBMockPeripheralManagerDelegate> mockDelegate;

@property (strong, nonatomic) NSMutableArray *services;
@property (copy, nonatomic) NSDictionary *advInfo;

- (void)respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result;
- (BOOL)updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;

- (void)fakeReadRequest:(CBATTRequest *)request;
- (void)fakeWriteRequest:(CBATTRequest *)request;
- (void)fakeNotifyState:(BOOL)enabled central:(CBCentral *)central characteristic:(CBMutableCharacteristic *)characteristic;
@end


@protocol RZBMockPeripheralManagerDelegate <NSObject>

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager startAdvertising:(NSDictionary *)advertisementData;
- (void)mockPeripheralManagerStopAdvertising:(RZBMockPeripheralManager *)peripheralManager;

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central;
- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager addService:(CBMutableService *)service;
- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager removeService:(CBMutableService *)service;
- (void)mockPeripheralManagerRemoveAllServices:(RZBMockPeripheralManager *)peripheralManager;

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result;
- (BOOL)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;


@end
