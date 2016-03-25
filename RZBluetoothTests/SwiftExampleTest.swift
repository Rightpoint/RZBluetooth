//
//  SwiftExampleTest.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

class SwiftExampleTestCase: RZBSimulatedTestCase {

    override class func simulatedDeviceClass() -> AnyClass! {
        return SimulatedPacketDevice.self
    }

    override func configureCentralManager() {
        self.centralManager = RZBCentralManager(identifier: "com.test", peripheralClass: PacketPeripheral.self, queue: nil)
    }

    func testPing() {
        var packets = Array<Packet>()
        // Need to figure out how to get RZBSimulatedTestCase to create better properties...
        guard let device = self.device as? SimulatedPacketDevice,
            let peripheral = self.peripheral as? PacketPeripheral else {
            fatalError("Invalid Configuration")
        }
        peripheral.setPacketObserver() {packet in
            packets.append(packet)
        }
        waitForQueueFlush()

        peripheral.writePacket(.Ping)
        waitForQueueFlush()
        XCTAssert(packets.count == 1)
        XCTAssert(device.packetHistory.count == 1)
    }

}