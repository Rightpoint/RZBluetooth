//
//  RZSimulatedConnection+Private.h
//  RZBluetooth
//
//  Created by Brian King on 2/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBSimulatedConnection.h"

@interface RZBSimulatedConnection ()

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                    peripheralName:(NSString *)peripheralName
                 peripheralManager:(RZBMockPeripheralManager *)peripheralManager
                           central:(RZBSimulatedCentral *)central;

- (BOOL)isDiscoverableWithServices:(NSArray *)services;

@property (strong, nonatomic, readonly) NSMutableArray *readRequests;
@property (strong, nonatomic, readonly) NSMutableArray *writeRequests;
@property (strong, nonatomic, readonly) NSMutableArray *subscribedCharacteristics;

/**
 Dictionary of dictionaries of static characteristic values
 provided by the service when it is added to the peripheral.
 Read handlers for static characteristics on simulated devices
 will never be called.
 
 Outer dictionary key is the service UUID.
 Inner dictionary key is the characteristic UUID.
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *staticCharacteristicValues;

@property (weak, nonatomic, readonly) RZBSimulatedCentral *central;
@property (strong, nonatomic) RZBMockPeripheral *peripheral;

@end
