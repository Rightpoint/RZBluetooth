//
//  RZBSimulatedCallback.m
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCallback.h"

static NSTimeInterval __defaultDelay = 0;

@interface RZBSimulatedCallback ()
@property (strong, nonatomic) NSMutableArray<dispatch_source_t> * timers;
@property (strong, nonatomic) dispatch_queue_t queue;
@end

@implementation RZBSimulatedCallback

+ (void)setDefaultDelay:(NSTimeInterval)delay
{
    __defaultDelay = delay;
}

+ (RZBSimulatedCallback *)callbackOnQueue:(dispatch_queue_t)queue
{
    queue = queue ?: dispatch_get_main_queue();
    RZBSimulatedCallback *cb = [[RZBSimulatedCallback alloc] initWithDispatchQueue:queue];
    return cb;
}

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        self.delay = __defaultDelay;
        self.timers = [NSMutableArray array];
        self.queue = queue;
    }
    return self;
}

@synthesize paused = _paused;

- (void)dealloc
{
    [self cancel];
}

- (void)dispatch:(RZBSimulatedCallbackBlock)block
{
    NSParameterAssert(block);
    NSError *injectError = self.injectError;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
    uint64_t delay = self.delay * NSEC_PER_SEC;
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, delay), 0, 0);
    __weak typeof(self) weakSelf = self;
    __weak dispatch_source_t weakTimer = timer;

    dispatch_source_set_event_handler(timer, ^{
        [weakSelf triggerBlock:block injectedError:injectError timer:weakTimer];
    });

    @synchronized(self) {
        [self.timers addObject:timer];
    }
    if (!self.paused) {
        dispatch_resume(timer);
    }
}

- (void)triggerBlock:(RZBSimulatedCallbackBlock)block injectedError:(NSError *)injectError timer:(dispatch_source_t)timer
{
    @synchronized (self) {
        [self.timers removeObject:timer];
        dispatch_cancel(timer);
    }
    block(injectError);
}

- (void)setPaused:(BOOL)paused
{
    @synchronized(self) {
        if (_paused != paused) {
            _paused = paused;
            for (dispatch_source_t timer in self.timers) {
                if (paused) {
                    dispatch_suspend(timer);
                }
                else {
                    dispatch_resume(timer);
                }
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

- (BOOL)idle
{
    @synchronized(self) {
        return _timers.count == 0;
    }
}

- (void)cancel
{
    @synchronized(self) {
        for (dispatch_source_t timer in self.timers) {
            // In Xcode 9+, you can not cancel an inactive / suspended timer.
            // So if the callback is paused, resume it before canceling
            if (self.paused) {
                dispatch_resume(timer);
            }
            dispatch_cancel(timer);
        }
        [self.timers removeAllObjects];
    }
}

@end
