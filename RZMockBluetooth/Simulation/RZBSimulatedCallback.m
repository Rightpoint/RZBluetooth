//
//  RZBSimulatedCallback.m
//  UMTSDK
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCallback.h"
typedef void(^RZBSimulatedDispatchBlock)(NSUInteger dispatchCounter);
typedef void(^RZBSimulatedBlock)(void);

static NSTimeInterval __defaultDelay = 0;

@interface RZBSimulatedCallback ()
@property (strong, nonatomic) dispatch_group_t group;
@property (strong, nonatomic) dispatch_queue_t queue;
@property (assign, nonatomic) NSUInteger dispatchCounter;
@property (assign, nonatomic) NSUInteger cancelCounter;
@property (assign, nonatomic) NSUInteger triggeredCounter;
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

- (void)withDispatchCounter:(RZBSimulatedDispatchBlock)block
{
    NSUInteger dispatchCounter = NSNotFound;
    @synchronized(self) {
        dispatchCounter = self.dispatchCounter;
        self.dispatchCounter += 1;
        block(dispatchCounter);
    }
 }

- (void)bounceDispatchGroupWithDelay:(NSTimeInterval)delay
{
    __weak typeof(self) wself = self;
    dispatch_group_enter(self.group);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), self.queue, ^{
        dispatch_group_t group = wself.group;
        if (group != nil) {
            dispatch_group_leave(group);
        }
    });
}

- (void)updateTriggerCounter:(NSUInteger)dispatchCounter and:(RZBSimulatedBlock)block
{
    __weak typeof(self) wself = self;
    dispatch_group_notify(self.group, self.queue, ^{
        wself.triggeredCounter = dispatchCounter;
        block();
    });
}

- (void)dispatchRunloopBlocker:(NSUInteger)count
{
    if (count > 0) {
        __weak typeof(self) wself = self;
        [self withDispatchCounter:^(NSUInteger idleDispatchCounter) {
            [self bounceDispatchGroupWithDelay:0.0];
            [self updateTriggerCounter:idleDispatchCounter and:^() {
                [wself dispatchRunloopBlocker:count - 1];
            }];
        }];
    }
}

- (void)dispatch:(RZBSimulatedCallbackBlock)block
{
    NSParameterAssert(block);
    __weak typeof(self) wself = self;
    [self withDispatchCounter:^(NSUInteger dispatchCounter) {
        [self bounceDispatchGroupWithDelay:self.delay];
        [self updateTriggerCounter:dispatchCounter and:^() {
            if (dispatchCounter >= wself.cancelCounter) {
                block(wself.injectError);
            }
            // This is a trick to help the simulated callback maintain a concept of 'idle'.
            // This will withold the callback from becoming idle for X more dispatch cycles. This
            // gives the application code the chance to submit a bluetooth command before the simulated
            // callback goes idle.
            //
            // This has to be more than 1. Since it it takes basically 0 time to run through them I'm
            // erroring on the side of excessive with 5.
            [wself dispatchRunloopBlocker:5];
        }];
    }];
}

- (BOOL)idle
{
    BOOL idle = YES;
    // If the dispatchCounter is 0 the callback has never been triggered
    if (self.dispatchCounter > 0) {
        // Dispatch counter always holds the next counter, so compare to the previous value.
        idle = (self.triggeredCounter == self.dispatchCounter - 1);
    }
    return idle;
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
