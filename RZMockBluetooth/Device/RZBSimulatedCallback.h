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

+ (RZBSimulatedCallback *)callback;

@property (assign, nonatomic) NSTimeInterval delay;
@property (strong, nonatomic) NSError *injectError;
@property (copy, nonatomic) RZBSimulatedCallbackBlock block;

- (void)dispatch:(RZBSimulatedCallbackBlock)block;

@end
