//
//  Packet.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

enum Packet {
    case ping
    case divide(value: UInt8, by: UInt8)
    case divideResponse(value: UInt8)
    case invalid
}

extension Packet {

    var commandValue: UInt8 {
        switch self {
        case .ping:
            return 0
        case .divide(_, _):
            return 1
        case .divideResponse(_):
            return 2
        case .invalid:
            return UInt8.max
        }
    }

    var data: Data {
        var data = Data()
        var c = commandValue
        data.append(&c, count: 1)
        switch self {
        case .ping:
            break
        case .divide(var value, var by):
            data.append(&value, count: 1)
            data.append(&by, count: 1)
        case .divideResponse(var value):
            data.append(&value, count: 1)
        case .invalid:
            break
        }
        return data
    }

    static func from(data: Data) -> Packet {
        let packet: Packet
        var command: UInt8 = 0

        data.copyBytes(to: &command, count: 1)
        switch command {
        case 0:
            packet = .ping
        case 1:
            var value: UInt8 = 0
            var by: UInt8 = 0

            data.copyBytes(to: &value, from: Range(uncheckedBounds: (1,1)))
            data.copyBytes(to: &by, from: Range(uncheckedBounds: (2,1)))
            packet = .divide(value: value, by: by)
        default:
            packet = .invalid
        }
        return packet
    }

}
