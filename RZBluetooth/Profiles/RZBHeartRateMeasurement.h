//
//  RZBHeartRateMeasurement.h
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (assign, nonatomic) UInt16 start;
@property (assign, nonatomic) UInt16 end;

@end

@interface RZBHeartRateMeasurement : NSObject

- (instancetype)initWithBluetoothData:(NSData *)data;

@property (assign, nonatomic) UInt16 heartRate; // Beats per minute
@property (assign, nonatomic) UInt16 energyExpended; // Kilo Joules
@property (assign, nonatomic) BOOL contactDetectionSupported;
@property (assign, nonatomic) BOOL contactDetected;
@property (strong, nonatomic) NSArray *rrIntervals;

@end
