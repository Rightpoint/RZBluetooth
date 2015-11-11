//
//  RZBPeripheralState.m
//  RZBluetooth
//
//  Created by Brian King on 11/11/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBPeripheralState.h"

@interface RZBPeripheralState ()

@property (strong, nonatomic, readonly) NSMutableDictionary *notifyBlockByUUID;

@end

@implementation RZBPeripheralState

@synthesize notifyBlockByUUID = _notifyBlockByUUID;

- (NSMutableDictionary *)notifyBlockByUUID
{
    if (_notifyBlockByUUID == nil) {
        _notifyBlockByUUID = [NSMutableDictionary dictionary];
    }
    return _notifyBlockByUUID;
}

- (RZBCharacteristicBlock)notifyBlockForCharacteristicUUID:(CBUUID *)characteristicUUID
{
    return self.notifyBlockByUUID[characteristicUUID];
}

- (void)setNotifyBlock:(RZBCharacteristicBlock)notifyBlock forCharacteristicUUID:(CBUUID *)characteristicUUID;
{
    if (notifyBlock) {
        self.notifyBlockByUUID[characteristicUUID] = [notifyBlock copy];
    }
    else {
        [self.notifyBlockByUUID removeObjectForKey:characteristicUUID];
    }
}

@end
