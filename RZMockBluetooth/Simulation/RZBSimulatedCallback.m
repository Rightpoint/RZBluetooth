//
//  RZBSimulatedCallback.m
//  UMTSDK
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCallback.h"

static NSTimeInterval __defaultDelay = 0;

@interface RZBSimulatedCallback ()
@property (strong, nonatomic) dispatch_group_t group;
@property (strong, nonatomic) dispatch_queue_t queue;
@property (assign, nonatomic) NSUInteger dispatchCounter;
@property (assign, nonatomic) NSUInteger cancelCounter;
@end

@implementation RZBSimulatedCallback

+ (void)setDefaultDelay:(NSTimeInterval)delay
{
    __defaultDelay = delay;
}

+ (RZBSimulatedCallback *)callbackOnQueue:(dispatch_queue_t)queue
{
    queue = queue ?: dispatch_get_main_queue();
    RZBSimulatedCallback *cb = [[RZBSimulatedCallback alloc] init];
    cb.delay = __defaultDelay;
    cb.group = dispatch_group_create();
    cb.queue = queue;
    return cb;
}

@synthesize paused = _paused;

- (void)dealloc
{
    _cancelCounter = NSNotFound;
    if (_paused) {
        dispatch_group_leave(_group);
    }
}

- (void)dispatch:(RZBSimulatedCallbackBlock)block
{
    NSParameterAssert(block);
    NSUInteger dispatchCounter = NSNotFound;
    @synchronized(self) {
        dispatchCounter = self.dispatchCounter;
        self.dispatchCounter += 1;
    }
    __weak typeof(self) wself = self;

    dispatch_group_enter(self.group);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delay * NSEC_PER_SEC)), self.queue, ^{
        dispatch_group_leave(wself.group);
    });

    dispatch_group_notify(self.group, self.queue, ^{
        if (dispatchCounter >= wself.cancelCounter) {
            block(wself.injectError);
        }
    });
}

- (void)setPaused:(BOOL)paused
{
    @synchronized(self) {
        if (_paused != paused) {
            _paused = paused;
            if (paused) {
                dispatch_group_enter(self.group);
            }
            else {
                dispatch_group_leave(self.group);
            }
        }
    }
}

- (BOOL)paused
{
    @synchronized(self) {
        return _paused;
    }
}

- (void)cancel
{
    @synchronized(self) {
        self.cancelCounter = self.dispatchCounter;
    }
}

@end
