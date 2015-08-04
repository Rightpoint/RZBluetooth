//
//  RZBTestService.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
@class RZBMockPeripheral;
@class RZBMockCharacteristic;

@interface RZBMockService : NSObject

@property(nonatomic) CBUUID *UUID;
@property(weak, nonatomic) RZBMockPeripheral *peripheral;
@property(nonatomic) BOOL isPrimary;
@property(strong) NSArray *characteristics;

- (RZBMockCharacteristic *)newCharacteristicForUUID:(CBUUID *)characteristicUUIUD;
- (RZBMockCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUIUD;

@end
