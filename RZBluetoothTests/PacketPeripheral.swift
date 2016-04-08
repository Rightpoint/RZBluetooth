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

    func setPacketObserver(newPacket: (Packet) -> Void) {
        enableNotifyForCharacteristicUUID(PacketUUID.fromDevice, serviceUUID: PacketUUID.service, onUpdate: { characteristic, error in
            if let characteristic = characteristic, data = characteristic.value {
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

    func writePacket(packet: Packet) {
        writeData(packet.data, characteristicUUID: PacketUUID.toDevice, serviceUUID: PacketUUID.service)
    }

}