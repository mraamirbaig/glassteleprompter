//
//  Ble.swift
//  Teleprompter
//
//  Created by abaig on 01/07/2025.
//

import Foundation

class GlassesResponse {
    var lr: GlassLensSide
    var data: Data = Data()
    var type: String = ""
    var isTimeout: Bool = false

    init(lr: GlassLensSide) {
        self.lr = lr
    }
    
    init(lr: GlassLensSide, isTimeout: Bool) {
        self.lr = lr
        self.isTimeout = isTimeout
    }

    static func fromMap(_ map: [String: Any], lr: GlassLensSide) -> GlassesResponse {
        let ret = GlassesResponse(lr: lr)
        if let rawData = map["data"] as? Data {
            ret.data = rawData
        } else if let byteArray = map["data"] as? [UInt8] {
            ret.data = Data(byteArray)
        }
        ret.type = map["type"] as? String ?? ""
        return ret
    }
}
extension Data {
    func getCmd() -> UInt8 {
        return self.first ?? 0x00
    }
}
