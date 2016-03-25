//
//  Packet.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

enum Packet {
    case Ping
    case Divide(value: Int8, by: Int8)
    case DivideResponse(value: Int8)
    case Invalid
}

extension Packet {

    var commandValue: UInt8 {
        switch self {
        case .Ping:
            return 0
        case .Divide(_, _):
            return 1
        case .DivideResponse(_):
            return 2
        case .Invalid:
            return UInt8.max
        }
    }

    var data: NSData {
        let data = NSMutableData()
        var c = commandValue
        data.appendBytes(&c, length: 1)
        switch self {
        case .Ping:
            break
        case .Divide(var value, var by):
            data.appendBytes(&value, length: 1)
            data.appendBytes(&by, length: 1)
        case .DivideResponse(var value):
            data.appendBytes(&value, length: 1)
        case .Invalid:
            break
        }
        return data
    }

    static func fromData(data: NSData) -> Packet {
        let packet: Packet
        var command: UInt8 = 0
        data.getBytes(&command, length: 1)
        switch command {
        case 0:
            packet = .Ping
        case 1:
            var value: Int8 = 0
            var by: Int8 = 0
            data.getBytes(&value, range:NSMakeRange(1, 1))
            data.getBytes(&by, range:NSMakeRange(2, 1))
            packet = .Divide(value: value, by: by)
        default:
            packet = .Invalid
        }
        return packet
    }

}
