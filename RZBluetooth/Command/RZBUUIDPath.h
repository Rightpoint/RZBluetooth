//
//  RZBUUIDPath.h
//  UMTSDK
//
//  Created by Brian King on 7/22/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

#define RZB_OVERLOADED FOUNDATION_EXTERN __attribute__((overloadable))

/**
 * A command filter is a helper object to store lookup state.
 * This is used internally to help lookup various command objects.
 *
 */
@interface RZBUUIDPath : NSObject

+ (NSArray *)UUIDkeys;

@property(strong, nonatomic, readonly) NSUUID *peripheralUUID;
@property(strong, nonatomic, readonly) CBUUID *serviceUUID;
@property(strong, nonatomic, readonly) CBUUID *characteristicUUID;

@property(assign, nonatomic, readonly) NSUInteger length;

- (void)enumerateUUIDsUsingBlock:(void (^)(id NSUUIDorCBUUID, NSUInteger idx))block;

@end

RZB_OVERLOADED RZBUUIDPath *RZBUUIDP(NSUUID *peripheralUUID);
RZB_OVERLOADED RZBUUIDPath *RZBUUIDP(NSUUID *peripheralUUID, CBUUID *serviceUUID);
RZB_OVERLOADED RZBUUIDPath *RZBUUIDP(NSUUID *peripheralUUID, CBUUID *serviceUUID, CBUUID *characteristicUUID);
