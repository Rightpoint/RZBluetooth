//
//  RZBMockCentralManager.h
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "RZBDefines.h"
@class RZBMockPeripheral;
@protocol RZBMockCentralManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface RZBMockCentralManager : NSObject

@property(weak, nonatomic) id<CBCentralManagerDelegate> delegate;
@property(weak, nonatomic) id<RZBMockCentralManagerDelegate> mockDelegate;
@property(strong, nonatomic) dispatch_queue_t queue;
@property(assign) CBManagerState state;
@property(strong) NSDictionary *options;
@property(strong) NSMutableDictionary *peripheralsByUUID;
@property(nonatomic, assign, readonly) BOOL isScanning;
@property(assign) NSUInteger fakeActionCount;

- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options;

- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;

- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs;

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options;

- (void)stopScan;

- (void)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary *)options;

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;

- (RZBMockPeripheral *)peripheralForUUID:(NSUUID *)uuid;

- (void)fakeStateChange:(CBManagerState)state;
- (void)fakeScanPeripheralWithUUID:(NSUUID *)peripheralUUID advInfo:(NSDictionary *)info RSSI:(NSNumber *)RSSI;

- (void)fakeConnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *__nullable)error;
- (void)fakeDisconnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *__nullable)error;

@end

@protocol RZBMockCentralManagerDelegate <NSObject>

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;
- (NSArray *)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs;
- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options;
- (void)mockCentralManagerStopScan:(RZBMockCentralManager *)mockCentralManager;

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options;
- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral;

@end

NS_ASSUME_NONNULL_END
