//
//  RZBCommandLog.h
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import Foundation;

/**
 *  Store a command log of the Fake CoreBluetooth methods
 *  that have been invoked.
 */
@interface RZBInvocationLog : NSObject

- (void)logSelector:(SEL)selector arguments:(id)firstObject, ...;

- (NSArray *)argumentsForSelector:(SEL)selector;
- (id)argumentAtIndex:(NSUInteger)index forSelector:(SEL)selector;
- (void)removeAllLogs;

@end