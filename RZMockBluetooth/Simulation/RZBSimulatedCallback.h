//
//  RZBSimulatedCallback.h
//  UMTSDK
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>


typedef void(^RZBSimulatedCallbackBlock)(NSError *injectedError);

@interface RZBSimulatedCallback : NSObject

+ (void)setDefaultDelay:(NSTimeInterval)delay;

+ (RZBSimulatedCallback *)callbackOnQueue:(dispatch_queue_t)queue;

@property (strong, nonatomic) dispatch_queue_t queue;
@property (assign, nonatomic) NSTimeInterval delay;
@property (strong, nonatomic) NSError *injectError;

- (void)dispatch:(RZBSimulatedCallbackBlock)block;

@end
