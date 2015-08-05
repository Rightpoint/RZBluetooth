//
//  CBService+RZBExtension.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBService+RZBExtension.h"

@implementation CBService (RZBExtension)

- (CBCharacteristic *)rzb_characteristicForUUID:(CBUUID *)characteristicUUID
{
    for (CBCharacteristic *characteristic in self.characteristics) {
        if ([characteristic.UUID isEqual:characteristicUUID]) {
            return characteristic;
        }
    }
    return nil;
}

@end
