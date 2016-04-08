//
//  RZBTestCentralManager.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "RZBMockedCentralManager.h"

@class RZBMockPeripheral;
@protocol RZBMockCentralManagerDelegate;

@interface RZBMockCentralManager : NSObject <RZBMockedCentralManager>

@property(weak, nonatomic) id<CBCentralManagerDelegate> delegate;
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

@end

