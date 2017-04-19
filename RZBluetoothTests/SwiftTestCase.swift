//
//  SwiftTestCase.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

class SwiftTestCase: RZBSimulatedTestCase {

    func tic() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        waitForQueueFlush()
    }

    func testScan() {
        var peripherals: [RZBPeripheral] = []
        centralManager.scanForPeripherals(withServices: nil, options: nil) { scanInfo, error in
            if let peripheral = scanInfo?.peripheral {
                peripherals.append(peripheral)
            }
            else {
                XCTFail("Should not get a scan error")
            }
        }
        tic()
        XCTAssert(peripherals.count == 0)
        device.peripheralManager.startAdvertising([:])
        tic()

        XCTAssert(peripherals.count == 1)
        centralManager.stopScan()
        waitForQueueFlush()
    }

    func testProperties() {
        XCTAssertNotNil(centralManager.coreCentralManager.mock)
        XCTAssertNotNil(device.peripheralManager.mock)
        XCTAssertNotNil(peripheral.corePeripheral.mock)
    }
}
