//
//  CBCharacteristic+RZBExtension.h
//  UMTSDK
//
//  Created by Brian King on 7/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

typedef void(^RZBCharacteristicCallback)(CBCharacteristic *characteristic, NSError *error);

@interface CBCharacteristic (RZBExtension)

/**
 * Storage for the onUpdate handler.
 */
@property (strong, nonatomic) RZBCharacteristicCallback notificationBlock;

@end