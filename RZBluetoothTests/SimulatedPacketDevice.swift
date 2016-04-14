//
//  SimulatedPacketDevice.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

class SimulatedPacketDevice: RZBSimulatedDevice {
    var packetHistory = Array<Packet>()
    var autoResponse = true

    let service = CBMutableService(type: PacketUUID.service, primary: true)
    let toDevice = CBMutableCharacteristic(type: PacketUUID.toDevice, properties: [.Write], value: nil, permissions: [.Writeable])
    let fromDevice = CBMutableCharacteristic(type: PacketUUID.fromDevice, properties: [.Notify], value: nil, permissions: [.Readable])

    override init(queue: dispatch_queue_t?, options: [NSObject : AnyObject]) {
        super.init(queue: queue, options: options)

        service.characteristics = [toDevice, fromDevice]
        addService(service)

        addWriteCallbackForCharacteristicUUID(PacketUUID.toDevice) { [weak self] request -> CBATTError in
            if let strongSelf = self, value = request.value {
                let pkt = Packet.fromData(value)
                strongSelf.handlePacket(pkt)
            }
            return .Success
        }

    }

    func handlePacket(packet: Packet) {
        packetHistory.append(packet)
        guard autoResponse == true else {
            return
        }

        switch packet {
        case .Ping:
            writePacket(packet)
        case let .Divide(value, by):
            if by > 0 {
                writePacket(.DivideResponse(value: value / by))
            }
            else {
                writePacket(.Invalid)
            }
        default:
            print("Ignoring \(packet)")
        }
    }

    func writePacket(packet: Packet) {
        peripheralManager.updateValue(packet.data, forCharacteristic: fromDevice, onSubscribedCentrals: nil)
    }
}