//
//  PacketUUID.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

struct PacketUUID {
    static let service = CBUUID(nsuuid: UUID())
    static let toDevice = CBUUID(nsuuid: UUID())
    static let fromDevice = CBUUID(nsuuid: UUID())
}
