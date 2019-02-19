//
//  NSError+RZBMock.m
//  RZBluetooth
//
//  Created by Brian King on 7/28/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "NSError+RZBMock.h"

@implementation NSError (RZBMock)

#if TARGET_OS_IOS
+ (NSError *)rzb_connectionError
{
    return [NSError errorWithDomain:CBErrorDomain code:CBErrorConnectionFailed userInfo:nil];
}
#endif

@end
