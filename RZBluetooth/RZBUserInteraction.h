//
//  RZBTimeout.h
//  RZBluetooth
//
//  Created by Brian King on 11/10/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RZBUserInteraction : NSObject

/**
 * Set the timeout for interactions that are performed inside of `-performUserInteraction:`.
 * This value defaults to 5 seconds.
 */
+ (void)setTimeout:(NSTimeInterval)timeout;

/**
 * Perform all interactions triggered inside the block with the timeout
 */
+ (void)perform:(void(^)(void))interaction;

/**
 * Enable or disable timeout for all interactions. The default value is NO.
 */
+ (void)setEnabled:(BOOL)enabled;

/**
 * Obtain the timeout value. The default value is 5 seconds.
 */
+ (NSTimeInterval)timeout;

/**
 * Check if timeouts are currently enabled.
 */
+ (BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
