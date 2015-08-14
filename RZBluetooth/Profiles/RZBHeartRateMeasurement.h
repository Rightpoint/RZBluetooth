//
//  RZBHeartRateMeasurement.h
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, RZBHeartRateSensorContact) {
    RZBHeartRateSensorContactNotSupported = 0,
    // 1 is a duplicate of 0 in the spec. Internally this is mapped to NotSupported.
    RZBHeartRateSensorContactNotDetected = 2,
    RZBHeartRateSensorContactDetected,
};

typedef NS_ENUM(uint8_t, RZBBodyLocation) {
    RZBBodyLocationOther,
    RZBBodyLocationChest,
    RZBBodyLocationWrist,
    RZBBodyLocationFinger,
    RZBBodyLocationHand,
    RZBBodyLocationEarLobe,
    RZBBodyLocationFoot,
    RZBBodyLocationReservedStart = 7,
    RZBBodyLocationReservedEnd   = 255,
};

/**
 * Keeping this object a bit crude, because I think there's a better abstraction
 * for API's, but I'm not sure what it is. Each interval has a start and end time,
 * and is cumulitave from the interval before.
 */
@interface RZBRRInterval : NSObject

@property (assign, nonatomic) uint8_t start;
@property (assign, nonatomic) uint8_t end;

@end

@interface RZBHeartRateMeasurement : NSObject

- (instancetype)initWithBluetoothData:(NSData *)data;

@property (assign, nonatomic) NSUInteger heartRate; // Beats per minute
@property (assign, nonatomic) NSUInteger energyExpended; // Kilo Joules
@property (assign, nonatomic) RZBHeartRateSensorContact sensorContact;
@property (strong, nonatomic) NSArray *rrIntervals;

@end
