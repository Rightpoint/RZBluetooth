//
//  NSRunLoop+RZBWaitFor.h
//  RZBluetooth
//
//  Created by Brian King on 8/5/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSRunLoop (RZBWaitFor)

/**
 * Wait for the condition to be true with the specified timeout.
 *
 * This method returns YES if the check passed before the timeout interval.
 */
- (BOOL)rzb_waitWithTimeout:(NSTimeInterval)timeout forCheck:(BOOL (^)(void))checkBlock;

- (void)rzb_handleSources;

@end
