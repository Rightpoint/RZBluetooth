//
//  RZBSimulatedCallback.m
//  UMTSDK
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCallback.h"

@implementation RZBSimulatedCallback

static NSTimeInterval __defaultDelay = 0;
+ (void)setDefaultDelay:(NSTimeInterval)delay
{
    __defaultDelay = delay;
}

+ (RZBSimulatedCallback *)callback
{
    RZBSimulatedCallback *cb = [[RZBSimulatedCallback alloc] init];
    cb.delay = __defaultDelay;
    return cb;
}

- (void)dispatch:(RZBSimulatedCallbackBlock)block
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.block) {
            self.block(self.injectError);
            self.block = nil;
        }
    });
}

@end
