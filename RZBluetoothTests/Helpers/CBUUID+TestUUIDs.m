//
//  CBUUID+TestUUIDs.m
//  RZBluetooth
//
//  Created by Brian King on 4/18/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "CBUUID+TestUUIDs.h"

@implementation CBUUID (TestUUIDs)

+ (CBUUID *)sUUID
{
    return [CBUUID UUIDWithString:@"0123"];
}

+ (CBUUID *)cUUID
{
    return [CBUUID UUIDWithString:@"1234"];
}

+ (CBUUID *)s2UUID
{
    return [CBUUID UUIDWithString:@"2345"];
}

+ (CBUUID *)c2UUID
{
    return [CBUUID UUIDWithString:@"2345"];
}

@end

@implementation NSUUID (TestUUIDs)

+ (NSUUID *)pUUID
{
    static NSUUID *UUID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UUID = [NSUUID UUID];
    });
    return UUID;
}

+ (NSUUID *)p2UUID
{
    static NSUUID *UUID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UUID = [NSUUID UUID];
    });
    return UUID;
}

@end

@implementation RZBUUIDPath (TestUUIDs)

+ (RZBUUIDPath *)pUUIDPath
{
    return RZBUUIDP(NSUUID.pUUID);
}

+ (RZBUUIDPath *)sUUIDPath
{
    return RZBUUIDP(NSUUID.pUUID, CBUUID.sUUID);
}

+ (RZBUUIDPath *)cUUIDPath
{
    return RZBUUIDP(NSUUID.pUUID, CBUUID.sUUID, CBUUID.cUUID);
}

@end