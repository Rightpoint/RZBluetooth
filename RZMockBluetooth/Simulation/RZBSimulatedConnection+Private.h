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
                 peripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager
                           central:(RZBSimulatedCentral *)central;

- (BOOL)isDiscoverableWithServices:(NSArray *)services;

@property (strong, nonatomic, readonly) NSMutableArray *readRequests;
@property (strong, nonatomic, readonly) NSMutableArray *writeRequests;
@property (strong, nonatomic, readonly) NSMutableArray *subscribedCharacteristics;

@property (strong, nonatomic, readonly) CBPeripheralManager<RZBMockedPeripheralManager> *peripheralManager;
@property (weak, nonatomic, readonly) RZBSimulatedCentral *central;
@property (strong, nonatomic) CBPeripheral<RZBMockedPeripheral> *peripheral;

@end
