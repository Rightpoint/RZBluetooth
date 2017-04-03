//
//  PacketPeripheral.swift
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import Foundation

class PacketPeripheral: RZBPeripheral {
    var packets: [Packet] = []

    func setPacketObserver(_ newPacket: @escaping (Packet) -> Void) {
        enableNotify(forCharacteristicUUID: PacketUUID.fromDevice, serviceUUID: PacketUUID.service, onUpdate: { characteristic, error in
            if let characteristic = characteristic, let data = characteristic.value {
                newPacket(Packet.fromData(data))
            }
            else if let error = error {
                print("Error handling is good \(error)")
            }
            }, completion: { characteristic, error in
                if let error = error {
                    print("Error handling is good \(error)")
                }
        })
    }

    func writePacket(_ packet: Packet) {
        write(packet.data, characteristicUUID: PacketUUID.toDevice, serviceUUID: PacketUUID.service)
    }

}
