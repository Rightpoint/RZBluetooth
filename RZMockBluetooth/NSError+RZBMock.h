//
//  NSError+RZBMock.h
//  UMTSDK
//
//  Created by Brian King on 7/28/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@interface NSError (RZBMock)

/**
 * Error object representing a Core Bluetooth disconnection.
 *
 * @note This error may be different from device to device.
 */
+ (NSError *)rzb_connectionError;

@end
