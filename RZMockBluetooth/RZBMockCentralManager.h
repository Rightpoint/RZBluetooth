//
//  RZBTestCentralManager.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
@class RZBMockPeripheral;
@class RZBInvocationLog;
@protocol RZBMockCentralManagerDelegate;

@interface RZBMockCentralManager : NSObject

@property(weak, nonatomic) id<CBCentralManagerDelegate> delegate;
@property(weak, nonatomic) id<RZBMockCentralManagerDelegate> mockDelegate;
@property(strong, nonatomic) dispatch_queue_t queue;
@property(assign) CBCentralManagerState state;
@property(strong) NSDictionary *options;
@property(strong) NSMutableDictionary *peripheralsByUUID;

- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options;

- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options;

- (void)stopScan;

- (void)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary *)options;

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;

- (RZBMockPeripheral *)peripheralForUUID:(NSUUID *)uuid;

- (void)fakeStateChange:(CBCentralManagerState)state;
- (void)fakeScanPeripheralWithUUID:(NSUUID *)peripheralUUID advInfo:(NSDictionary *)info RSSI:(NSNumber *)RSSI;

- (void)fakeConnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error;
- (void)fakeDisconnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error;

@end

@protocol RZBMockCentralManagerDelegate <NSObject>

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;
- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options;
- (void)mockCentralManagerStopScan:(RZBMockCentralManager *)mockCentralManager;

- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options;
- (void)mockCentralManager:(RZBMockCentralManager *)mockCentralManager cancelPeripheralConnection:(RZBMockPeripheral *)peripheral;

@end