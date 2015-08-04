//
//  CBService+RZBExtension.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBService (RZBExtension)

- (CBCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID;

@end

@interface CBMutableService (RZBExtension)

- (CBMutableCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID;

@end