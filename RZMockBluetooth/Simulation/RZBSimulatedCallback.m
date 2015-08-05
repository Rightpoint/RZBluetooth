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

+ (RZBSimulatedCallback *)callbackOnQueue:(dispatch_queue_t)queue
{
    queue = queue ?: dispatch_get_main_queue();
    RZBSimulatedCallback *cb = [[RZBSimulatedCallback alloc] init];
    cb.delay = __defaultDelay;
    cb.queue = queue;
    return cb;
}

- (void)dispatch:(RZBSimulatedCallbackBlock)block
{
    NSParameterAssert(block);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delay * NSEC_PER_SEC)), self.queue, ^{
        if (block) {
            block(self.injectError);
        }
    });
}

@end
