//
//  NSError+RZBMock.m
//  UMTSDK
//
//  Created by Brian King on 7/28/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSError+RZBMock.h"

@implementation NSError (RZBMock)

+ (NSError *)rzb_connectionError
{
    return [NSError errorWithDomain:CBErrorDomain code:CBErrorConnectionFailed userInfo:nil];
}

@end
