//
//  RZBDebug.h
//  RZBluetooth
//
//  Created by Brian King on 12/9/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  The log levels used by RZBluetooth
 */
typedef NS_ENUM(NSUInteger, RZBLogLevel) {
    /// Log messages related to command dependencies
    RZBLogLevelCommand = 1 << 1,
    /// Log the written data
    RZBLogLevelWriteCommandData = 1 << 2,
    /// Log all CoreBluetooth delegate interactions (Except Data)
    RZBLogLevelDelegate = 1 << 3,
    /// Log data values sent by CoreBluetooth
    RZBLogLevelDelegateValue = 1 << 4,
    /// Log configuration issues
    RZBLogLevelConfiguration = 1 << 5,
    /// Log Bluetooth device simulation messages
    RZBLogLevelSimulatedDevice = 1 << 6,
    /// Log Bluetooth connection simulation messages
    RZBLogLevelSimulation = 1 << 7,
};

typedef void(^RZBLogHandler)(RZBLogLevel logLevel, NSString *format, va_list args);

/**
 * Configure a log handler. This can print via NSLog or integrated with other logging libraries.
 */
FOUNDATION_EXPORT void RZBSetLogHandler(RZBLogHandler);
FOUNDATION_EXPORT RZBLogHandler RZBGetLogHandler(void);
