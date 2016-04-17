//
//  RZBHeartRateMeasurement.m
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBHeartRateMeasurement.h"

// Defines to help parse the heart rate characteristic. These could
// be public, but they shouldn't be needed.
typedef NS_ENUM(uint8_t, RZBHeartRateValueFormat) {
    RZBHeartRateValueFormatUInt8 = 0,
    RZBHeartRateValueFormatUInt16
};

typedef NS_ENUM(uint8_t, RZBHeartRateSensorContactSupport) {
    RZBHeartRateSensorContactNotSupported = 0,  // Sensor does not support skin contact detection
    RZBHeartRateSensorContactSupported          // Sensor does support skin contact detection
};

typedef NS_ENUM(uint8_t, RZBHeartRateSensorContactDetection) {
    RZBHeartRateSensorContactNotDetected = 0,   // Skin contact not detected
    RZBHeartRateSensorContactDetected           // Skin contact detected
};

typedef NS_ENUM(uint8_t, RZBHeartRateSupportEnergyExpended) {
    RZBHeartRateSupportEnergyExpendedNotAvailable = 0,
    RZBHeartRateSupportEnergyExpendedAvailable
};

typedef NS_ENUM(uint8_t, RZBHeartRateSupportRRInterval) {
    RZBHeartRateSupportRRIntervalNotAvailable,
    RZBHeartRateSupportRRIntervalAvailable
};

struct RZBHeartRateFlags {
    RZBHeartRateValueFormat             format:1;
    RZBHeartRateSensorContactDetection  contactDetected:1;
    RZBHeartRateSensorContactSupport    supportContactDetection:1;
    RZBHeartRateSupportEnergyExpended   supportEnergyExpended:1;
    RZBHeartRateSupportRRInterval       supportRRInterval:1;
    uint8_t reserved:3;
};

@implementation RZBRRInterval

- (NSString*)description {
    return [NSString stringWithFormat:@"<RRInterval(%d, %d)>", self.start, self.end];
}

@end

@implementation RZBHeartRateMeasurement

- (instancetype)initWithBluetoothData:(NSData *)data
{
    self = [super init];
    if (self) {
        struct RZBHeartRateFlags flags;
        NSUInteger offset = 0;
        [data getBytes:&flags range:NSMakeRange(offset, sizeof(struct RZBHeartRateFlags))];
        offset += sizeof(struct RZBHeartRateFlags);

        if (flags.supportContactDetection) {
            _contactDetectionSupported = YES;
            _contactDetected = (flags.contactDetected == RZBHeartRateSensorContactDetected);
        }
        else {
            _contactDetectionSupported = NO;
            _contactDetected = NO;
        }

        if (flags.format == RZBHeartRateValueFormatUInt8) {
            UInt8 heartRate = 0;
            [data getBytes:&heartRate range:NSMakeRange(offset, sizeof(UInt8))];
            offset += sizeof(UInt8);
            _heartRate = heartRate;
        }
        else {
            UInt16 heartRate = 0;
            [data getBytes:&heartRate range:NSMakeRange(offset, sizeof(UInt16))];
            offset += sizeof(UInt16);
            // Profile specifies little-endian byte order; fix up 16-bit values if necessary.
            _heartRate = CFSwapInt16LittleToHost(heartRate);
        }

        if (flags.supportEnergyExpended) {
            [data getBytes:&_energyExpended range:NSMakeRange(offset, sizeof(UInt16))];
            offset += sizeof(UInt16);
            // Profile specifies little-endian byte order; fix up 16-bit values if necessary.
            _energyExpended = CFSwapInt16LittleToHost(_energyExpended);
        }

        if (flags.supportRRInterval) {
            NSMutableArray *rrIntervals = @[].mutableCopy;
            while (offset < data.length) {
                UInt16 start;
                UInt16 end;
                [data getBytes:&start range:NSMakeRange(offset, sizeof(UInt16))];
                offset += sizeof(UInt16);
                [data getBytes:&end   range:NSMakeRange(offset, sizeof(UInt16))];
                offset += sizeof(UInt16);
                RZBRRInterval *interval = [[RZBRRInterval alloc] init];
                // Profile specifies little-endian byte order; fix up 16-bit values if necessary.
                interval.start = CFSwapInt16LittleToHost(start);
                interval.end   = CFSwapInt16LittleToHost(end);
                [rrIntervals addObject:interval];
            }
            _rrIntervals = [rrIntervals copy];
        }
    }
    return self;
}

@end
