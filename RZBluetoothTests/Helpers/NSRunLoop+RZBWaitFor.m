//
//  NSRunLoop+RZBWaitFor.m
//  RZBluetooth
//
//  Created by Brian King on 8/5/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSRunLoop+RZBWaitFor.h"

NSTimeInterval const kFRYRunLoopSpinInterval = 0.05;

@implementation NSRunLoop (RZBWaitFor)

- (BOOL)rzb_waitWithTimeout:(NSTimeInterval)timeout forCheck:(BOOL (^)(void))checkBlock
{
    // Process any sources that have work pending, before checking the check block.
    [self rzb_handleSources];

    // Spin the runloop, checking the check block any time the runloop reports
    // that something happened.
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    NSTimeInterval remainingTimeout = [endDate timeIntervalSinceNow];
    BOOL ok = checkBlock();
    while( ok == NO && remainingTimeout > 0 ) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, remainingTimeout, true);
        ok = checkBlock();
        remainingTimeout = [endDate timeIntervalSinceNow];
    }
    [self rzb_handleSources];

    return ok;
}

- (void)rzb_handleSources
{
    while ( CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true) == kCFRunLoopRunHandledSource ) {}
}

@end
