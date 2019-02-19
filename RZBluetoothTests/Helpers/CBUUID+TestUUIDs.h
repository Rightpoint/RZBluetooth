//
//  CBUUID+TestUUIDs.h
//  RZBluetooth
//
//  Created by Brian King on 4/18/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "RZBluetooth/RZBUUIDPath.h"

/**
 * This category is a bucket for assorted NSUUID, CBUUID, and RZBUUIDPath objects.
 */
@interface CBUUID (TestUUIDs)

+ (CBUUID *)sUUID;
+ (CBUUID *)cUUID;

+ (CBUUID *)s2UUID;
+ (CBUUID *)c2UUID;

@end

@interface NSUUID (TestUUIDs)

+ (NSUUID *)pUUID;
+ (NSUUID *)p2UUID;

@end

@interface RZBUUIDPath (TestUUIDs)

+ (RZBUUIDPath *)pUUIDPath;
+ (RZBUUIDPath *)sUUIDPath;
+ (RZBUUIDPath *)cUUIDPath;

@end
