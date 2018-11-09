//
//  RZBSimulatedDevice.h
//  RZBluetooth
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@protocol RZBMockPeripheralManagerDelegate;

#if (TARGET_OS_IOS && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0) || \
(TARGET_OS_TV && __TV_OS_VERSION_MIN_REQUIRED < __TVOS_10_0) || \
(TARGET_OS_WATCH && __WATCH_OS_VERSION_MIN_REQUIRED < __WATCHOS_3_0) || \
(TARGET_OS_OSX && MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_13)
#define RZBPeripheralManagerState CBPeripheralManagerState
#define RZBPeripheralManagerStatePoweredOn CBPeripheralManagerStatePoweredOn
#else
#define RZBPeripheralManagerState CBManagerState
#define RZBPeripheralManagerStatePoweredOn CBManagerStatePoweredOn
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Mock API for CBPeripheralManager. This is not a direct subclass of CBPeripheralManager
 * because not all of the things can be controlled (like peripheralManagerDidUpdateState: signaling)
 */
@interface RZBMockPeripheralManager : NSObject

- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue;
- (instancetype)initWithDelegate:(id<CBPeripheralManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options;

@property (weak, nonatomic, readonly) id<CBPeripheralManagerDelegate>delegate;
@property () RZBPeripheralManagerState state;

@property (readonly) BOOL isAdvertising;

- (void)startAdvertising:(NSDictionary *)advertisementData;
- (void)stopAdvertising;
- (void)setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central;
- (void)addService:(CBMutableService *)service;
- (void)removeService:(CBMutableService *)service;
- (void)removeAllServices;

@property (weak, nonatomic) id<RZBMockPeripheralManagerDelegate> mockDelegate;

@property (copy, nonatomic) NSDictionary *advInfo;
@property (strong, nonatomic, readonly) NSMutableArray *services;
@property (copy, nonatomic, readonly) NSDictionary *options;
@property (copy, nonatomic, readonly) dispatch_queue_t queue;
@property(assign) NSUInteger fakeActionCount;

- (void)respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result;
- (BOOL)updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;

- (void)fakeStateChange:(RZBPeripheralManagerState)state;
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

NS_ASSUME_NONNULL_END
