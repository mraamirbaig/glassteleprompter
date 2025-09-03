//
//  Untitled.swift
//  Teleprompter
//
//  Created by abaig on 01/07/2025.
//

struct ArmInfo {
    let lr: GlassLensSide
    let batteryPercent: Int
    let isCharging: Bool
//    let isArmClosed: Bool
//    let voltage: Double  // in volts

//    var description: String {
//        return "[\(lr)] Battery: \(batteryPercent)%, Charging: \(isCharging)"
//    }

    init?(side: GlassLensSide, data: Data) {
        guard data.count >= 4 else {
            return nil
        }

        let batteryPercent = Int(data[2])

        let flags = data[3]
        let isCharging = (flags & 0x01) != 0
//        let isArmClosed = (flags & 0x02) != 0
//
//        let voltageRaw = (Int(data[4]) << 8) | Int(data[5])
//        let voltage = Double(voltageRaw) / 1000.0

        self.lr = side
        self.batteryPercent = batteryPercent
        self.isCharging = isCharging
//        self.isArmClosed = isArmClosed
//        self.voltage = voltage
    }
}


//struct ArmInfo {
//    let lr: String
//    let batteryPercent: Int
//    let isCharging: Bool
//    let isArmClosed: Bool
//    let voltage: Double  // in volts
//
//    var description: String {
//        return "[\(lr)] Battery: \(batteryPercent)%, Charging: \(isCharging), Arm Closed: \(isArmClosed), Voltage: \(String(format: "%.2f", voltage)) V"
//    }
//
//    init?(side: String, data: Data) {
//        guard data.count >= 4 else {
//            return nil
//        }
//
//        let batteryPercent = Int(data[0])
//
//        let flags = data[1]
//        let isCharging = (flags & 0x01) != 0
//        let isArmClosed = (flags & 0x02) != 0
//
//        let voltageRaw = (Int(data[2]) << 8) | Int(data[3])
//        let voltage = Double(voltageRaw) / 1000.0
//
//        self.lr = side
//        self.batteryPercent = batteryPercent
//        self.isCharging = isCharging
//        self.isArmClosed = isArmClosed
//        self.voltage = voltage
//    }
//}
