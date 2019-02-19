//
//  RZBSimulatedCallback.h
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import Foundation;

typedef void(^RZBSimulatedCallbackBlock)(NSError *__nullable injectedError);

NS_ASSUME_NONNULL_BEGIN
/**
 * A simulated callback is a method of controlling the timing and error
 * injection of a callback performed by a simulated connection.
 *
 * By default, all callbacks will trigger after 0 seconds with no injected 
 * errors. The callback can be controlled to delay the callback, or inject
 * an error into the testing process.
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
@property (assign) NSTimeInterval delay;

/**
 * The error to inject into the dispatched block.
 */
@property (strong) NSError *injectError;

/**
 * Determine if the callback is idle. A callback is idle when every block dispatched
 * to the callback has been executed.
 */
@property (readonly) BOOL idle;

/**
 * Do not dispatch any blocks while paused. This will not pause the delay that
 * the dispatch is invoked with.
 */
@property () BOOL paused;

/**
 * Dispatch a block that will be triggered when the delay passes, and the callback
 * is not paused.
 */
- (void)dispatch:(RZBSimulatedCallbackBlock)block;

/**
 * do not execute any blocks that have been dispatched to this point.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
