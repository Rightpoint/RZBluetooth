//
//  RZBSimulatedDevice.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "RZBMockPeripheral.h"
#import "RZBMockPeripheralManager.h"

@class RZBSimulatedCallback;
@class RZBSimulatedCentral;
@class CBATTRequest;

/**
 *  A simulated connection controls the interactions between a CBPeripheralManager
 *  and the client facing CBPeripheral.
 *
 *  For simple integration testing, calling `startAdvertising` on the CBPeripheralManager
 *  will cause the peripheral to be discoverable. Use the `connectable` property on the
 *  connection to make the peripheral connectable..
 *
 *  Look into the RZBSimulatedCallback API to inject delay or errors to specific 
 *  callback methods. The connection contains a number of RZBSimulatedCallback objects
 *  to control timing and error injected. The properties describe the callbacks that
 *  they encapsulate.
 */
@interface RZBSimulatedConnection : NSObject <RZBMockPeripheralDelegate, RZBMockPeripheralManagerDelegate>

/**
 *  The identifier of the associated peripheral
 */
@property (strong, nonatomic, readonly) NSUUID *identifier;

/**
 *  The RSSI to simulate for the peripheral.
 */
@property (strong, nonatomic) NSNumber *RSSI;

/**
 *  A boolean to model the connected state to the peripheral.
 */
@property (assign, nonatomic) BOOL connectable;

- (void)disconnect;

/**
 *  The scanCallback property controls how the mockCentralManager:scanForPeripheralsWithServices:options:
 *  callback should be responded to. The callback will trigger fakeScanPeripheralWithUUID:advInfo:RSSI:
 *  when the callback is not paused, after the specified delay.
 *
 *  The injectError will cause an assertion if it is set, since an error can not be injected.
 */
@property (strong, nonatomic) RZBSimulatedCallback *scanCallback;

/**
 *  The cancelConnectionCallback property controls how the disconnect method behaves. The
 *  callback will call fakeDisconnectPeripheralWithUUID:error: when the callback is not paused,
 *  after the specified delay, and will pass in the `injectError` property if set.
 */
@property (strong, nonatomic) RZBSimulatedCallback *cancelConncetionCallback;

/**
 *  The connectCallback property controls how the mockCentralManager:connectPeripheral:options:
 *  callback should be responded to. The callback will trigger fakeConnectPeripheralWithUUID:error:
 *  when the callback is not paused, after the specified delay, and will pass in the `injectError`
 *  property if set.
 */
@property (strong, nonatomic) RZBSimulatedCallback *connectCallback;

/**
 *  The discoverServiceCallback property controls how the mockPeripheral:discoverServices:
 *  callback should be responded to. The callback will trigger fakeDiscoverService:error:
 *  when the callback is not paused, after the specified delay, and will pass in the `injectError`
 *  property if set.
 */
@property (strong, nonatomic) RZBSimulatedCallback *discoverServiceCallback;

/**
 *  The discoverCharacteristicCallback property controls how the mockPeripheral:discoverCharacteristics:forService:
 *  callback should be responded to. The callback will trigger fakeDiscoverCharacteristics:forService:error:
 *  when the callback is not paused, after the specified delay, and will pass in the `injectError`
 *  property if set.
 */
@property (strong, nonatomic) RZBSimulatedCallback *discoverCharacteristicCallback;

/**
 *  The readRSSICallback property controls how the mockPeripheralReadRSSI:
 *  callback should be responded to. The callback will trigger fakeRSSI:error:
 *  when the callback is not paused, after the specified delay, and will pass in the `injectError`
 *  property if set.
 */
@property (strong, nonatomic) RZBSimulatedCallback *readRSSICallback;

/**
 *  The readCharacteristicCallback property controls how the mockPeripheral:readValueForCharacteristic:
 *  callback should be responded to. If no error is injected, the connection will create a CBATTRequest
 *  and call the RZBMockPeripheralManager fakeReadRequest: when the callback is not paused, after the
 *  specified delay. If the `injectError` property is set, the callback will trigger
 *  fakeCharacteristic:updateValue:error: with the specified error.
 */
@property (strong, nonatomic) RZBSimulatedCallback *readCharacteristicCallback;

/**
 *  The writeCharacteristicCallback property controls how the mockPeripheral:writeValueForCharacteristic:type:
 *  callback should be responded to. If no error is injected, the connection will create a CBATTRequest
 *  and call the RZBMockPeripheralManager fakeWriteRequest: when the callback is not paused, after the
 *  specified delay. If the `injectError` property is set, the callback will trigger
 *  fakeCharacteristic:writeResponseWithError: with the specified error.
 */
@property (strong, nonatomic) RZBSimulatedCallback *writeCharacteristicCallback;

/**
 *  The notifyCharacteristicCallback property controls how the mockPeripheral:setNotifyValue:forCharacteristic:
 *  callback should be responded to. The callback will trigger fakeCharacteristic:notify:error:
 *  when the callback is not paused, after the specified delay, and will pass in the `injectError`
 *  property if set. if no error is injected, the callback will call the RZBMockPeripheralManager
 *  fakeNotifyState:central:characteristic method to inform the peripheral manager of the 
 *  notification state change.
 */
@property (strong, nonatomic) RZBSimulatedCallback *notifyCharacteristicCallback;

/**
 *  The requestCallback property controls how the mockPeripheralManager:respondToRequest:withResult:
 *  callback should be responded to. When the callback is not paused and after the specified delay,
 *  if the connection is still active, the callback will trigger fakeCharacteristic:updateValue:error:
 *  or fakeCharacteristic:writeResponseWithError: depending on if the request is a read or write.
 */
@property (strong, nonatomic) RZBSimulatedCallback *requestCallback;

/**
 *  The updateCallback property controls how the mockPeripheralManager:updateValue:forCharacteristic:onSubscribedCentrals:
 *  callback should be responded to. When the callback is not paused and after the specified delay,
 *  if the connection is still active, the callback will trigger fakeCharacteristic:updateValue:error:
 *  with the injected error.
 */
@property (strong, nonatomic) RZBSimulatedCallback *updateCallback;

@end
