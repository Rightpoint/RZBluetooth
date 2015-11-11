//
//  RZBCentralManagerState.m
//  RZBluetooth
//
//  Created by Brian King on 11/11/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBCentralManagerState.h"
#import "RZBPeripheralState.h"

@interface RZBCentralManagerState ()

@property (strong, nonatomic, readonly) NSMutableDictionary *peripheralStateByUUID;

@end

@implementation RZBCentralManagerState

@synthesize peripheralStateByUUID = _peripheralStateByUUID;

- (NSMutableDictionary *)peripheralStateByUUID
{
    if (_peripheralStateByUUID == nil) {
        _peripheralStateByUUID = [NSMutableDictionary dictionary];
    }
    return _peripheralStateByUUID;
}

- (RZBPeripheralState *)stateForIdentifier:(NSUUID *)identifier
{
    RZBPeripheralState *state = self.peripheralStateByUUID[identifier];
    if (state == nil) {
        state = [[RZBPeripheralState alloc] init];
        self.peripheralStateByUUID[identifier] = state;
    }
    return state;
}

@end
