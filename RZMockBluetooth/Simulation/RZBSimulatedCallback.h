//
//  RZBSimulatedCallback.h
//  UMTSDK
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>


typedef void(^RZBSimulatedCallbackBlock)(NSError *injectedError);

/**
 * A simulated callback is a method of controlling the timing and error
 * injection of a callback performed by a simulated connection.
 */
@interface RZBSimulatedCallback : NSObject

/**
 * Specify the default delay for all new simulated callbacks.
 */
+ (void)setDefaultDelay:(NSTimeInterval)delay;

/**
 * Return a new callback on the specified dispatch queue. If queue is nil,
 * the main queue will be used.
 */
+ (RZBSimulatedCallback *)callbackOnQueue:(dispatch_queue_t)queue;

/**
 * The dispatch queue that will be used.
 */
@property (strong, nonatomic, readonly) dispatch_queue_t queue;

/**
 * The delay to use for all future `dispatch:` calls.
 */
@property (assign, nonatomic) NSTimeInterval delay;

/**
 * The error to inject into the dispatched block.
 */
@property (strong, nonatomic) NSError *injectError;

/**
 * Do not dispatch any blocks while paused. This will not pause the delay that
 * the dispatch is invoked with.
 */
@property (assign, nonatomic) BOOL paused;

/**
 * Dispatch a block that will be triggered when the delay passes, and the callback
 * is not paused.
 */
- (void)dispatch:(RZBSimulatedCallbackBlock)block;

@end
