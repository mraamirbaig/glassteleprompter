//
//  Proto.swift
//  Teleprompter
//
//  Created by abaig on 30/06/2025.
//

import Foundation

class Proto {
    private static var beatHeartSeq: Int = 0

    static func sendHeartBeat() async -> Bool {
        let length = 6
        let seq = UInt8(beatHeartSeq % 0xff)
        let data: [UInt8] = [
            0x25,
            UInt8(length & 0xff),
            UInt8((length >> 8) & 0xff),
            seq,
            0x04,
            seq
        ]
        beatHeartSeq += 1

        let now = Date()
        print("\(now) sendHeartBeat--------data---\(data)--")

        let retL = await BleManager.shared.request(Data(data), lr: GlassLensSide.Left, timeoutMs: 1500)

        print("\(Date()) sendHeartBeat----L----ret---\(retL.data as NSData)--")

        if retL.isTimeout {
            print("\(Date()) sendHeartBeat----L----timeout--")
            return false
        } else if retL.data.getCmd() == 0x25,
                  retL.data.count > 5,
                  retL.data[4] == 0x04 {

            let retR = await BleManager.shared.request(Data(data), lr: GlassLensSide.Right, timeoutMs: 1500)

            print("\(Date()) sendHeartBeat----R----retR---\(retR.data as NSData)--")

            if retR.isTimeout {
                return false
            } else if retR.data.getCmd() == 0x25,
                      retR.data.count > 5,
                      retR.data[4] == 0x04 {
                return true
            } else {
                return false
            }

        } else {
            return false
        }
    }
}
