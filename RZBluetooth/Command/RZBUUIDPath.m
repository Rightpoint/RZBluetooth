//
//  RZBUUIDPath.m
//  UMTSDK
//
//  Created by Brian King on 7/22/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBUUIDPath.h"

@interface RZBUUIDPath () {
@public
    NSUUID *_peripheralUUID;
    CBUUID *_serviceUUID;
    CBUUID *_characteristicUUID;
}

@end

@implementation RZBUUIDPath

+ (NSArray *)UUIDkeys
{
    return @[NSStringFromSelector(@selector(peripheralUUID)),
             NSStringFromSelector(@selector(serviceUUID)),
             NSStringFromSelector(@selector(characteristicUUID))];
}

- (NSUInteger)length
{
    return self.characteristicUUID ? 3 : self.serviceUUID ? 2 : self.peripheralUUID ? 1 : 0;
}

- (void)enumerateUUIDsUsingBlock:(void (^)(id NSUUIDorCBUUID, NSUInteger idx))block
{
    NSParameterAssert(block);
    [[self.class UUIDkeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        id value = [self valueForKey:key];
        if (value) {
            block(value, idx);
        }
    }];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p", self.class, self];
    [[self.class UUIDkeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        id value = [self valueForKey:key];
        if (value) {
            [description appendFormat:@" %@=%@", key, [value UUIDString]];
        }
    }];
    [description appendString:@">"];
    return description;
}

@end

RZB_OVERLOADED RZBUUIDPath *RZBUUIDP(NSUUID *peripheralUUID)
{
    NSCAssert(peripheralUUID != nil, @"Must specify peripheralUUID");
    RZBUUIDPath *path = [[RZBUUIDPath alloc] init];
    path->_peripheralUUID = peripheralUUID;
    return path;
}

RZB_OVERLOADED RZBUUIDPath *RZBUUIDP(NSUUID *peripheralUUID, CBUUID *serviceUUID)
{
    NSCAssert(peripheralUUID != nil, @"Must specify peripheralUUID");
    NSCAssert(serviceUUID != nil, @"Must specify serviceUUID");
    RZBUUIDPath *path = [[RZBUUIDPath alloc] init];
    path->_peripheralUUID = peripheralUUID;
    path->_serviceUUID = serviceUUID;
    return path;
}

RZB_OVERLOADED RZBUUIDPath *RZBUUIDP(NSUUID *peripheralUUID, CBUUID *serviceUUID, CBUUID *characteristicUUID)
{
    NSCAssert(peripheralUUID != nil, @"Must specify peripheralUUID");
    NSCAssert(serviceUUID != nil, @"Must specify serviceUUID");
    NSCAssert(characteristicUUID != nil, @"Must specify characteristicUUID");
    RZBUUIDPath *path = [[RZBUUIDPath alloc] init];
    path->_peripheralUUID = peripheralUUID;
    path->_serviceUUID = serviceUUID;
    path->_characteristicUUID = characteristicUUID;
    return path;
}
