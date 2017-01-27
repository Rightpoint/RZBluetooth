//
//  RZBLog+Private.h
//  RZBluetooth
//
//  Created by Brian King on 12/9/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBLog.h"

void RZBLog(RZBLogLevel level, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);

#define RZBLogDelegate(fmt, ...) RZBLog(RZBLogLevelDelegate, fmt, ##__VA_ARGS__)
#define RZBLogDelegateValue(fmt, ...) RZBLog(RZBLogLevelDelegateValue, fmt, ##__VA_ARGS__)
#define RZBLogCommand(fmt, ...) RZBLog(RZBLogLevelCommand, fmt, ##__VA_ARGS__)
#define RZBLogSimulatedDevice(fmt, ...) RZBLog(RZBLogLevelSimulatedDevice, fmt, ##__VA_ARGS__)
#define RZBLogSimulation(fmt, ...) RZBLog(RZBLogLevelSimulation, fmt, ##__VA_ARGS__)

#define RZBLogBool(expr) expr ? @"YES" : @"NO"
#define RZBLogArray(array) [NSString stringWithFormat:@"@[%@]", [array componentsJoinedByString:@", "]]
#define RZBLogUUIDArray(objects) RZBLogArray([objects valueForKeyPath:RZB_KEYPATH(CBService, UUID.UUIDString)])
#define RZBLogUUID(object) object.UUID.UUIDString
#define RZBLogIdentifier(object) object.identifier.UUIDString
