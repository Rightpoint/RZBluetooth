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
    let toDevice = CBMutableCharacteristic(type: PacketUUID.toDevice, properties: [.write], value: nil, permissions: [.writeable])
    let fromDevice = CBMutableCharacteristic(type: PacketUUID.fromDevice, properties: [.notify], value: nil, permissions: [.readable])

    override init(queue: DispatchQueue?, options: [AnyHashable : Any] = [:]) {
        super.init(queue: queue, options: options)

        service.characteristics = [toDevice, fromDevice]
        addService(service)

        addWriteCallback(forCharacteristicUUID: PacketUUID.toDevice) { [weak self] request -> CBATTError.Code in
            if let strongSelf = self, let value = request.value {
                let pkt = Packet.from(data: value)
                strongSelf.handle(packet: pkt)
            }
            return .success
        }

    }

    func handle(packet: Packet) {
        packetHistory.append(packet)
        guard autoResponse == true else {
            return
        }

        switch packet {
        case .ping:
            write(packet: packet)
        case let .divide(value, by):
            if by > 0 {
                write(packet: .divideResponse(value: value / by))
            }
            else {
                write(packet: .invalid)
            }
        default:
            print("Ignoring \(packet)")
        }
    }

    func write(packet: Packet) {
        peripheralManager.updateValue(packet.data, for: fromDevice, onSubscribedCentrals: nil)
    }
}
