//
//  RZBDebug.m
//  RZBluetooth
//
//  Created by Brian King on 12/9/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBLog.h"

static RZBLogHandler RZBGlobalLogHandler = nil;

RZBLogHandler RZBGetLogHandler(void)
{
    return RZBGlobalLogHandler;
}

void RZBSetLogHandler(RZBLogHandler handler)
{
    RZBGlobalLogHandler = handler;
}

void RZBLog(RZBLogLevel level, NSString *format, ...) {
    if (RZBGlobalLogHandler) {
        va_list args;
        va_start(args, format);
        RZBGlobalLogHandler(level, format, args);
        va_end(args);
    }
}