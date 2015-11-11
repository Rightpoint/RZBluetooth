//
//  RZBTimeout.m
//  RZBluetooth
//
//  Created by Brian King on 11/10/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBUserInteraction.h"

static BOOL RZBTimeoutEnabled = NO;
static NSTimeInterval RZBTimeoutValue = 5.0;

@implementation RZBUserInteraction

+ (void)setTimeout:(NSTimeInterval)timeout
{
    RZBTimeoutValue = timeout;
}

+ (void)perform:(void(^)(void))interaction
{
    BOOL enabled = self.enabled;
    self.enabled = YES;
    interaction();
    self.enabled = enabled;
}

+ (void)setEnabled:(BOOL)enabled
{
    RZBTimeoutEnabled = enabled;
}

+ (NSTimeInterval)timeout
{
    return RZBTimeoutValue;
}

+ (BOOL)enabled
{
    return RZBTimeoutEnabled;
}

@end
