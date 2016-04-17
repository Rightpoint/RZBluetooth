//
//  PacketUUID.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

struct PacketUUID {
    static let service = CBUUID(NSUUID: NSUUID())
    static let toDevice = CBUUID(NSUUID: NSUUID())
    static let fromDevice = CBUUID(NSUUID: NSUUID())
}