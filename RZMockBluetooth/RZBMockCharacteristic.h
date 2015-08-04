//
//  RZBTestCharacteristic.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
typedef void(^RZBMockCharacteristicCallback)(CBCharacteristic *characteristic, NSError *error);

@class RZBMockService;

@interface RZBMockCharacteristic : NSObject

- (instancetype)initWithType:(CBUUID *)UUID properties:(CBCharacteristicProperties)properties value:(NSData *)value permissions:(CBAttributePermissions)permissions NS_DESIGNATED_INITIALIZER;

@property(nonatomic) CBUUID *UUID;
@property(weak, nonatomic) RZBMockService *service;
@property(nonatomic) CBCharacteristicProperties properties;
@property(nonatomic) CBAttributePermissions permissions;
@property(strong) NSData *value;
@property(assign) BOOL isNotifying;
@property(copy) RZBMockCharacteristicCallback notificationBlock;

@end
