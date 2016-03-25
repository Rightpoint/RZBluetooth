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
        NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
        waitForQueueFlush()
    }

    func testScan() {
        var peripherals: [RZBPeripheral] = []
        connection.connectable = false;
        connection.scanCallback.paused = true
        centralManager.scanForPeripheralsWithServices(nil, options: nil) { scanInfo, error in
            if let peripheral = scanInfo?.peripheral {
                peripherals.append(peripheral)
            }
            else {
                XCTFail("Should not get a scan error")
            }
        }
        tic()
        XCTAssert(peripherals.count == 0)
        connection.scanCallback.paused = false
        tic()

        XCTAssert(peripherals.count == 1)
        centralManager.stopScan()
        waitForQueueFlush()
    }

}
