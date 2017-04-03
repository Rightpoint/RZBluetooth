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
    case divide(value: Int8, by: Int8)
    case divideResponse(value: Int8)
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
        let data = NSMutableData()
        var c = commandValue
        data.append(&c, length: 1)
        switch self {
        case .ping:
            break
        case .divide(var value, var by):
            data.append(&value, length: 1)
            data.append(&by, length: 1)
        case .divideResponse(var value):
            data.append(&value, length: 1)
        case .invalid:
            break
        }
        return data as Data
    }

    static func fromData(_ data: Data) -> Packet {
        let packet: Packet
        let nsData = data as NSData
        var command: UInt8 = 0
        nsData.getBytes(&command, length: 1)
        switch command {
        case 0:
            packet = .ping
        case 1:
            var value: Int8 = 0
            var by: Int8 = 0
            nsData.getBytes(&value, range:NSMakeRange(1, 1))
            nsData.getBytes(&by, range:NSMakeRange(2, 1))
            packet = .divide(value: value, by: by)
        default:
            packet = .invalid
        }
        return packet
    }

}
