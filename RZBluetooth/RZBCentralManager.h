//
//  RZCentralManager.h
//  UMTSDK
//
//  Created by Brian King on 7/22/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

/**
 * RZCentralManager encapsulates all delegate interactions, exposing only the high
 * level Bluetooth actions. RZCentralManager will automatically connect, and
 * discover any needed services or characteristics. It will also wait for 
 * Core Bluetooth to become available, and even re-submit any commands if the 
 * CoreBluetooth process crashes.
 */
@interface RZBCentralManager : NSObject

/**
 * Create a new central manager on the main dispatch queue, with a default identifier.
 */
- (instancetype)init;

/**
 * Create a new central manager
 *
 * @param identifier the restore identifier.
 * @param queue the dispatch queue for the central to use. The main queue will be used if queue is nil.
 *              It is important that the dispatch queue be a serial queue
 *
 */
- (instancetype)initWithIdentifier:(NSString *)identifier queue:(dispatch_queue_t)queue;

/**
 * Helper to get a peripheral from a peripheralUUID
 */
- (CBPeripheral *)peripheralForUUID:(NSUUID *)peripheralUUID;

/**
 * This block will be triggered whenever the central manager state encounters an error state.
 */
@property (nonatomic, copy) RZBCentralManagerStateChangeBlock centralStateIssueHandler;

/**
 * Scan for peripherals with the specified UUIDs and options. Trigger the scanBlock
 * for every discovered peripheral. Multiple calls to this method will replace the previous
 * calls.
 */
- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs
                               options:(NSDictionary *)options
                onDiscoveredPeripheral:(RZBScanBlock)scanBlock;

/**
 * Stop the peripheral scan.
 */
- (void)stopScan;

/**
 * This will maintain a connection to the peripheral at all times,
 * reconnecting to the peripheral when the connection fails. This is 
 * one of the most common patterns for connecting to a device with
 * battery limitations. When using this pattern, all device communication
 * should be initiated inside of the onConnection block.
 *
 * @param peripheralUUID The UUID of the peripheral to connect to
 */
- (void)maintainConnectionToPeripheralUUID:(NSUUID *)peripheralUUID
                              onConnection:(RZBPeripheralBlock)onConnection;

/**
 * Cancel the connection to a peripheral. This will cancel the connection
 * if connected. If the peripheral is not connected, it trigger the completion
 * block immediately. If the peripheral has a maintained connection, the 
 * reconnect behavior will also be cancelled.
 *
 * @param peripheralUUID The UUID of the peripheral to connect to
 */
- (void)cancelConnectionFromPeripheralUUID:(NSUUID *)peripheralUUID
                                completion:(RZBPeripheralBlock)completion;

/**
 * Initiate a connection to a peripheral. This is exposed in case
 * someone wants to use it directly, but all of the above commands
 * will initiate a connection if needed, so this method is not needed.
 */
- (void)connectToPeripheralUUID:(NSUUID *)peripheralUUID
                     completion:(RZBPeripheralBlock)completion;


@end
