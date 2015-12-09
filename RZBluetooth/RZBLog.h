//
//  RZBDebug.h
//  RZBluetooth
//
//  Created by Brian King on 12/9/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RZBLogLevel) {
    RZBLogLevelCommand = 1 << 1,
    RZBLogLevelWriteCommandData = 1 << 2,
    RZBLogLevelDelegate = 1 << 3,
    RZBLogLevelDelegateValue = 1 << 4,
};

typedef void(^RZBLogHandler)(RZBLogLevel logLevel, NSString *format, va_list args);

FOUNDATION_EXPORT RZBLogHandler RZBGetLogHandler(void);
FOUNDATION_EXPORT void RZBSetLogHandler(RZBLogHandler);
