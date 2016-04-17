//
//  RZBPeripheralStateEvent.h
//  RZBluetooth
//
//  Created by Brian King on 4/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

/**
 * This enum models the types of connection events that happen to a peripherl. There is no symetry between
 * connect success/failure and disconnected. This is because disconnection always succeeds, and an error object
 * does not indicate the device is still connected.
 *
 * The periheral is informed of the connection and disconnection events via the `onDisconnect` block. The
 * intent of the block is to inform the user that the connection succeeded, failed, or that the device was disconnected.
 * The consumer can use this information to determine what action to perform for connection maintainence.
 *
 * This does not reflect the state of the peripheral, continue to use CBPeripheral.state for that information.
 */
typedef NS_ENUM(NSUInteger, RZBPeripheralStateEvent) {
    RZBPeripheralStateEventConnectSuccess,
    RZBPeripheralStateEventConnectFailure,
    RZBPeripheralStateEventDisconnected,
};

