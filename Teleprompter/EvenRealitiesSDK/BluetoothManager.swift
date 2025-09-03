//
//  BluetoothManager.swift
//  Teleprompter
//
//  Created by abaig on 31/07/2025.
//


import CoreBluetooth
import Combine

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BluetoothManager()
    
    var centralManager: CBCentralManager!
    var peripheralPairBasedOnId: [String: (CBPeripheral?, CBPeripheral?)] = [:]
    var currentConnectingGlasses: Glasses?
    
    var bleEventPublisher = PassthroughSubject<GlassesResponse, Never>()
    
    var UARTServiceUUID:CBUUID
    var UARTRXCharacteristicUUID:CBUUID
    var UARTTXCharacteristicUUID:CBUUID
    
    var leftWChar:CBCharacteristic?
    var rightWChar:CBCharacteristic?
    var leftRChar:CBCharacteristic?
    var rightRChar:CBCharacteristic?
    
    private var isBluetoothReady = false
//    private var pendingStartScan: Bool = false
    
    private var leftHeartbeatReceived = false
    private var rightHeartbeatReceived = false
    

    override init() {
        UARTServiceUUID          = CBUUID(string: ServiceIdentifiers.uartServiceUUIDString)
        UARTTXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartTXCharacteristicUUIDString)
        UARTRXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartRXCharacteristicUUIDString)
        
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: bleQueue)
    }
    
    func startScan() {
        guard isBluetoothReady else {
//            pendingStartScan = true
            return
        }
        
        guard centralManager.state == .poweredOn else {
            
            return
        }

        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }


    func stopScan() {
        centralManager.stopScan()
    }

    func connectToDevice(glasses: Glasses) {
        
        resetConnectionFlags()
        stopScan()
        currentConnectingGlasses = glasses

        centralManager.connect(glasses.leftDevice, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true]) //   options nil
        centralManager.connect(glasses.rightDevice, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true]) //   options nil
    }

    func disconnectFromGlasses() {
                
        resetConnectionFlags()
        if let connectedGlasses = BleManager.shared.connectedGlasses {
            
            centralManager.cancelPeripheralConnection(connectedGlasses.leftDevice)
            centralManager.cancelPeripheralConnection(connectedGlasses.rightDevice)
        }
        BleManager.shared.onGlassesDisconnected()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, let channelNumber = getChannelNumberFromPeripheral(peripheral) else {
            return
        }

        print("device.....");
        print(name);
        print("\(channelNumber)");
        // Proceed with pairing logic
        if name.contains("_L_") {
            peripheralPairBasedOnId["\(channelNumber)", default: (nil, nil)].0 = peripheral
        } else if name.contains("_R_") {
            peripheralPairBasedOnId["\(channelNumber)", default: (nil, nil)].1 = peripheral
        }

        if let leftPeripheral = peripheralPairBasedOnId["\(channelNumber)"]?.0,
           let rightPeripheral = peripheralPairBasedOnId["\(channelNumber)"]?.1 {
            
            guard let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data, let serialNumber = GlassSerialNumber.init(from: manufacturerData) else {
                return
            }
            let glasses: Glasses = Glasses(
                leftDevice: leftPeripheral,
                rightDevice: rightPeripheral,
                channelNumber: channelNumber,
                serialNumber: serialNumber
            )
            
            BleManager.shared.onPairedGlassesFound(glasses: glasses)
        }
    }


    private func getChannelNumberFromPeripheral(_ peripheral: CBPeripheral) -> String? {
        guard let name = peripheral.name else { return nil }
        let components = name.components(separatedBy: "_")
        guard components.count > 1 else { return nil }
        return components[1]
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let _ = currentConnectingGlasses else { return }

        // Assign and setup the connected peripheral
        if currentConnectingGlasses!.leftDevice.identifier.uuidString == peripheral.identifier.uuidString {
            currentConnectingGlasses!.leftDevice = peripheral
            currentConnectingGlasses!.leftDevice.delegate = self
            currentConnectingGlasses!.leftDevice.discoverServices([UARTServiceUUID])
        } else if currentConnectingGlasses!.rightDevice.identifier.uuidString == peripheral.identifier.uuidString {
            currentConnectingGlasses!.rightDevice = peripheral
            currentConnectingGlasses!.rightDevice.delegate = self
            currentConnectingGlasses!.rightDevice.discoverServices([UARTServiceUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        print("\(Date()) didDisconnectPeripheral-----peripheral-----\(peripheral)--")
        
        if let error = error {
            print("Disconnect error: \(error.localizedDescription)")
        } else {
            print("Disconnected without error.")
        }
//        if let connectedGlasses = BleManager.shared.connectedGlasses {
            disconnectFromGlasses()
//            BleManager.shared.onGlassesDisconnected()
//        }
    
        BleManager.shared.startScan()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\(Date()) didFailToConnect-----peripheral-----\(peripheral)--")
        
        if let error = error {
            print("Disconnect error: \(error.localizedDescription)")
        } else {
            print("Disconnected without error.")
        }
        resetConnectionFlags()
        BleManager.shared.onGlassesDisconnected()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("peripheral------\(peripheral)-----didDiscoverServices--------")
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid.isEqual(UARTServiceUUID){
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("peripheral------\(peripheral)-----didDiscoverCharacteristicsFor----service----\(service)----")
        guard let characteristics = service.characteristics else { return }

        if service.uuid.isEqual(UARTServiceUUID){
            for characteristic in characteristics {
                if characteristic.uuid.isEqual(UARTRXCharacteristicUUID){
                    if(peripheral.identifier.uuidString == currentConnectingGlasses?.leftDevice.identifier.uuidString){
                        print("settingleft_R_characteristic")
                        self.leftRChar = characteristic
                    }else if(peripheral.identifier.uuidString == currentConnectingGlasses?.rightDevice.identifier.uuidString){
                        print("settingright_R_characteristic")
                        self.rightRChar = characteristic
                    }
                } else if characteristic.uuid.isEqual(UARTTXCharacteristicUUID){
                    if(peripheral.identifier.uuidString == currentConnectingGlasses?.leftDevice.identifier.uuidString){
                        print("settingleft_W_characteristic")
                        self.leftWChar = characteristic
                    }else if(peripheral.identifier.uuidString == currentConnectingGlasses?.rightDevice.identifier.uuidString){
                        print("settingright_W_characteristic")
                        self.rightWChar = characteristic
                    }
                }
            }
            
            if peripheral.identifier.uuidString == currentConnectingGlasses?.leftDevice.identifier.uuidString {
                if let rx = self.leftRChar, let _ = self.leftWChar {
                    peripheral.setNotifyValue(true, for: rx)
                }
            } else if peripheral.identifier.uuidString == currentConnectingGlasses?.rightDevice.identifier.uuidString {
                if let rx = self.rightRChar, let _ = self.rightWChar {
                    peripheral.setNotifyValue(true, for: rx)
                }
            }
        }
    }
        
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("subscribe fail: \(error)")
            return
        }
        if characteristic.isNotifying {
            print("✅ subscribe success: \(characteristic.uuid) for \(peripheral.name ?? "")")

            if characteristic.uuid == UARTRXCharacteristicUUID {
                let heartbeatCmd: [UInt8] = [0x4d, 0x01]

                if peripheral == currentConnectingGlasses?.leftDevice, let tx = leftWChar {
                    peripheral.writeValue(Data(heartbeatCmd), for: tx, type: .withResponse)
                } else if peripheral == currentConnectingGlasses?.rightDevice, let tx = rightWChar {
                    peripheral.writeValue(Data(heartbeatCmd), for: tx, type: .withResponse)
                }
                // Start 10s timeout (only once, when both writes are done)
//                    if leftWChar != nil && rightWChar != nil && !leftHeartbeatReceived && !rightHeartbeatReceived {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//                            guard let self = self else { return }
//                            if !(self.leftHeartbeatReceived && self.rightHeartbeatReceived) {
//                                print("⚠️ Timeout waiting for heartbeat response from both sides")
//                                self.resetConnectionFlags()
//                                BleManager.shared.onGlassesDisconnected()
//                            }
//                        }
//                    }
            }
        }
 else {
            print("subscribe cancel")
        }
    }


    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothReady = true
            print("Bluetooth is powered on.")
            
            // If scan was requested before readiness, resume it now
//            if pendingStartScan == true {
            BleManager.shared.startScan()
//                pendingStartScan = false
//            }

        case .poweredOff:
            isBluetoothReady = false
            disconnectFromGlasses()
            print("Bluetooth is powered off.")
            
        default:
            isBluetoothReady = false
            print("Bluetooth state is unknown or unsupported.")
        }
    }
    
    func writeData(writeData: Data, lr: GlassLensSide) {
        if lr == GlassLensSide.Left {
            if self.leftWChar != nil {
                BleManager.shared.connectedGlasses?.leftDevice.writeValue(writeData, for: self.leftWChar!, type: .withoutResponse)
            }
            return
        }
        if lr == GlassLensSide.Right {
            if self.rightWChar != nil {
                BleManager.shared.connectedGlasses?.rightDevice.writeValue(writeData, for: self.rightWChar!, type: .withoutResponse)
            }
            return
        }
        
        if let leftWChar = self.leftWChar {
            BleManager.shared.connectedGlasses?.leftDevice.writeValue(writeData, for: leftWChar, type: .withoutResponse)
        } else {
            print("writeData leftWChar is nil, cannot write data to right peripheral.")
        }

        if let rightWChar = self.rightWChar {
            BleManager.shared.connectedGlasses?.rightDevice.writeValue(writeData, for: rightWChar, type: .withoutResponse)
        } else {
            print("writeData rightWChar is nil, cannot write data to right peripheral.")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("\(Date()) didWriteValueFor----characteristic---\(characteristic)---- \(error!)")
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("\(Date()) didWriteValueFor----------- \(error!)")
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else { return }

        let data = [UInt8](value)
        
        // Check if this is a heartbeat response (example match — adjust if your protocol differs)
        if data.first == 0x4D && data.count >= 2 {
            if peripheral == currentConnectingGlasses?.leftDevice {
                leftHeartbeatReceived = true
            } else if peripheral == currentConnectingGlasses?.rightDevice {
                rightHeartbeatReceived = true
            }

            // ✅ Call onGlassesConnected only when both heartbeats received
            if leftHeartbeatReceived && rightHeartbeatReceived,
               let glasses = currentConnectingGlasses {
                    print("onGlassesConnected")
                                BleManager.shared.onGlassesConnected(glasses)
                                self.currentConnectingGlasses = nil
                                self.leftHeartbeatReceived = false
                                self.rightHeartbeatReceived = false
            }
        }

        guard let data = characteristic.value else { return }
        print("📩 didUpdateValueFor \(peripheral.name ?? ""): \(data.getCmd())")
        self.getCommandValue(data: data, cbPeripheral: peripheral)
    }
    
    private func resetConnectionFlags() {
        leftHeartbeatReceived = false
        rightHeartbeatReceived = false
//        currentConnectingGlasses = nil
    }
    
    func getCommandValue(data:Data, cbPeripheral: CBPeripheral? = nil){
        
        guard BleManager.shared.connectedGlasses != nil else {
            return
        }
        
        let rspCommand = AG_BLE_REQ(rawValue: (data[0]))
        switch rspCommand{

            default:
          
                let isLeft = cbPeripheral?.identifier.uuidString == BleManager.shared.connectedGlasses!.leftDevice.identifier.uuidString
                let legStr = isLeft ? GlassLensSide.Left : GlassLensSide.Right
                var dictionary = [String: Any]()
                dictionary["type"] = "type" // todo
                dictionary["data"] = data
                
            bleEventPublisher.send(GlassesResponse.fromMap(dictionary, lr: legStr))

                break
        }
    }
}

// Extension for safe array indexing
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
