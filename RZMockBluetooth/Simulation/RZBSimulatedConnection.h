//
//  RZBSimulatedDevice.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "RZBMockPeripheral.h"
#import "RZBMockPeripheralManager.h"

@class RZBSimulatedCallback;
@class RZBSimulatedCentral;
@class CBATTRequest;

@interface RZBSimulatedConnection : NSObject <RZBMockPeripheralDelegate, RZBMockPeripheralManagerDelegate>

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                 peripheralManager:(RZBMockPeripheralManager *)peripheralManager
                           central:(RZBSimulatedCentral *)central;

- (BOOL)isDiscoverableWithServices:(NSArray *)services;

@property (strong, nonatomic, readonly) NSUUID *identifier;

@property (strong, nonatomic) NSNumber *RSSI;
@property (strong, nonatomic, readonly) NSMutableArray *readRequests;
@property (strong, nonatomic, readonly) NSMutableArray *writeRequests;

@property (weak, nonatomic, readonly) RZBSimulatedCentral *central;
@property (strong, nonatomic, readonly) RZBMockPeripheralManager *peripheralManager;
@property (strong, nonatomic) RZBMockPeripheral *peripheral;

@property (strong, nonatomic) RZBSimulatedCallback *scanCallback;
@property (strong, nonatomic) RZBSimulatedCallback *connectCallback;
@property (strong, nonatomic) RZBSimulatedCallback *cancelConncetionCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverServiceCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *readRSSICallback;

@property (strong, nonatomic) RZBSimulatedCallback *readCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *writeCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *notifyCharacteristicCallback;

@end
