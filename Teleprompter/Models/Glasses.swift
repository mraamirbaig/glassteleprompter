//
//  Glasses.swift
//  Teleprompter
//
//  Created by abaig on 30/06/2025.
//

import CoreBluetooth

enum GlassesStatus {
    case glassesInCaseLidOpen
    case glassesInCaseLidClosed
    case glassestNotWorn
    case glassesWorn
}

enum GlassLensSide: String {
    case Left
    case Right
}

class Glasses: ObservableObject {
    var leftDevice: CBPeripheral
    var rightDevice: CBPeripheral
    var channelNumber: String
    var serialNumber: GlassSerialNumber
    var glassCharging: Bool = false
    var caseCharging: Bool = false
    var caseBatteryCharge: Int?
    @Published var dashboardOpen: Bool = false
    @Published var isConnected: Bool = false
    @Published var glassStatus: GlassesStatus = .glassestNotWorn
    @Published var leftArmInfo: ArmInfo? = nil
    @Published var rightArmInfo: ArmInfo? = nil
    
    init(
        leftDevice: CBPeripheral,
        rightDevice: CBPeripheral,
        channelNumber: String,
        serialNumber: GlassSerialNumber
    ) {
        self.leftDevice = leftDevice
        self.rightDevice = rightDevice
        self.channelNumber = channelNumber
        self.serialNumber = serialNumber
    }
}
