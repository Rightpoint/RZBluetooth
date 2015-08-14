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

typedef NS_ENUM(uint8_t, RZBHeartRateSupportEnergyExpended) {
    RZBHeartRateSupportEnergyExpendedNotAvailable = 0,
    RZBHeartRateSupportEnergyExpendedAvailable
};

typedef NS_ENUM(uint8_t, RZBHeartRateSupportRRInterval) {
    RZBHeartRateSupportRRIntervalNotAvailable,
    RZBHeartRateSupportRRIntervalAvailable
};

// The spec has two values for not supported.
static uint8_t RZBHeartRateSensorContactAlsoNotSupported = 1;

struct RZBHeartRateFlags {
    RZBHeartRateValueFormat format:1;
    RZBHeartRateSensorContact contact:2;
    RZBHeartRateSupportEnergyExpended supportEnergyExpended:1;
    RZBHeartRateSupportRRInterval supportRRInterval:1;
    uint8_t reserved:3;
};

@implementation RZBRRInterval

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

        if (flags.contact == RZBHeartRateSensorContactAlsoNotSupported) {
            _sensorContact = RZBHeartRateSensorContactNotSupported;
        }
        else {
            _sensorContact = flags.contact;
        }
        size_t heartRateSize = (flags.format == RZBHeartRateValueFormatUInt8) ? sizeof(uint8_t) : sizeof(uint16_t);
        [data getBytes:&_heartRate range:NSMakeRange(offset, heartRateSize)];
        offset += heartRateSize;
        if (flags.supportEnergyExpended) {
            [data getBytes:&_energyExpended range:NSMakeRange(offset, sizeof(uint16_t))];
            offset += sizeof(uint16_t);
        }
        if (flags.supportRRInterval) {
            NSMutableArray *rrIntervals = [NSMutableArray array];
            while (offset < data.length) {
                uint8_t start;
                uint8_t end;
                [data getBytes:&start range:NSMakeRange(offset, sizeof(uint8_t))];
                [data getBytes:&end range:NSMakeRange(offset + 1, sizeof(uint8_t))];
                offset += sizeof(uint16_t);
                RZBRRInterval *interval = [[RZBRRInterval alloc] init];
                interval.start = start;
                interval.end = end;
                [rrIntervals addObject:interval];
            }
            _rrIntervals = [rrIntervals copy];
        }
    }
    return self;
}

@end
