//
//  RZBUUIDPath.h
//  UMTSDK
//
//  Created by Brian King on 7/22/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

/**
 * A UUIDPath is a helper object to assist help looking up objects. It's used as
 * a method of identifying a peripheral, service, or characteristic.
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
