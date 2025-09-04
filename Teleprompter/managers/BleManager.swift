//
//  BleManager.swift
//  Teleprompter
//
//  Created by abaig on 30/06/2025.
//

import Foundation
import Combine

let bleQueue = DispatchQueue(label: "com.teleprompter.BleManagerQueue", qos: .userInitiated)

class BleManager: ObservableObject {
    
    private var bluetoothManager = BluetoothManager.shared
    
    
    static let shared = BleManager()
    
    private init() {
        self.loadLastConnectedChannel()
        self.startListening()
        startScan()
    }
    
    @Published var isScanning = false
    @Published var isConnecting = false
    @Published var isDisconnecting = false
    @Published var connectedGlasses: Glasses? = nil
    
    @Published var pairedGlasses: [Glasses] = []
    
    private var scanTimer: DispatchSourceTimer?
    private var heartbeatSource: DispatchSourceTimer?
    private var userManuallyDisconnected = false
    private var lastConnectedChannel: String?
    
    var bleCancellable: AnyCancellable?
    
    private var _pendingBmp: Data?          // Optional Data (similar to Uint8List?)
    private var _isSendingBmp: Bool = false
    
    private var reqListen = [String: CheckedContinuation<GlassesResponse, Never>]()
    private var reqTimeout = [String: Timer]()
    private var nextReceive: CheckedContinuation<GlassesResponse, Never>?
    
    // MARK: - Init and State
    private func loadLastConnectedChannel() {
        let defaults = UserDefaults.standard
        self.lastConnectedChannel = defaults.string(forKey: "lastConnectedChannel")
        self.userManuallyDisconnected = defaults.bool(forKey: "userManuallyDisconnected")
    }
    
    private func saveLastConnectedChannel(_ channel: String?, disconnected: Bool = false) {
        let defaults = UserDefaults.standard
        if let channel = channel {
            defaults.set(channel, forKey: "lastConnectedChannel")
        }
        defaults.set(disconnected, forKey: "userManuallyDisconnected")
        self.userManuallyDisconnected = disconnected
    }
    
    // MARK: - BLE Scanning
    func startScan() {
        print("Start scanning in Swift")
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.isConnecting = false
            self.pairedGlasses = []
        }
        
//        // Prevent duplicate scans
//        if isScanning {
            stopScan()
//        }
//        
        
        
        bluetoothManager.startScan()
        
        let timer = DispatchSource.makeTimerSource(queue: bleQueue)
        timer.schedule(deadline: .now(), repeating: 1)
        // Check every second if previously connected glasses are found
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            guard let lastChannel = self.lastConnectedChannel,
                  !self.userManuallyDisconnected else { return }
            
            if let target = self.pairedGlasses.first(where: { $0.channelNumber == lastChannel }) {
                self.stopScan()
                Task {
                    await self.connectToGlasses(target)
                    self.saveLastConnectedChannel("\(target.channelNumber)", disconnected: false)
                }
            }
        }
        
        timer.resume()
        scanTimer = timer
        
//        // Stop scan after 20 seconds no matter what
//        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
//            guard let self = self else { return }
//            if self.isScanning {
//                print("Scan timed out after 30 seconds")
//                self.stopScan()
//            }
//        }
    }

    
    func stopScan() {
        
//        guard self.isScanning == true else { return }
        print("stop scan in Swift")
        DispatchQueue.main.async {
            self.isScanning = false
        }
        bluetoothManager.stopScan()
        scanTimer?.cancel()
        scanTimer = nil
    }
    
    // MARK: - BLE Connection
    func connectToGlasses(_ glasses: Glasses) async {
        DispatchQueue.main.async {
            BleManager.shared.isConnecting = true
        }
        self.bluetoothManager.connectToDevice(glasses: glasses)
        saveLastConnectedChannel(glasses.channelNumber, disconnected: false)
//        DispatchQueue.main.async {
//            BleManager.shared.isConnecting = false
//        }
    }
    
    func rebootGlasses() async -> Bool {
            // Command 0x23, Subcommand 0x72
            let command: [UInt8] = [0x23, 0x72]
         //let _ = await BleManager.shared.request(Data(command), lr: GlassLensSide.Left, timeoutMs: 1500)
        let _ = await BleManager.shared.request(Data(command), lr: GlassLensSide.Right, timeoutMs: 1500)
        
        print("Sent reboot command to glasses")
        
//        if result.isTimeout {
//            return false
//        }else {
            return true
//        }
    }
    
    func disconnectFromGlasses(_ glasses: Glasses) async {
        stopScan()
        DispatchQueue.main.async {
            self.isDisconnecting = true
        }
        saveLastConnectedChannel(glasses.channelNumber, disconnected: true)
        self.bluetoothManager.disconnectFromGlasses()
        DispatchQueue.main.async {
            self.connectedGlasses = nil
            self.isDisconnecting = false
        }
        reqListen = [String: CheckedContinuation<GlassesResponse, Never>]()
        reqTimeout = [String: Timer]()
        nextReceive = nil
        _pendingBmp = nil
        _isSendingBmp = false
    }
    
    func onPairedGlassesFound(glasses: Glasses) {

        let isAlreadyPaired = pairedGlasses.contains { pairedGlass in
            pairedGlass.channelNumber == glasses.channelNumber
        }
        print("glasses.channelNumber1")
        if !isAlreadyPaired {
            
            DispatchQueue.main.async {
                self.pairedGlasses.append(glasses)
            }
            
            print("glasses.channelNumber2")
            print(glasses.channelNumber)
        }
    }
    
    func onGlassesConnected(_ glasses: Glasses) {
        #if DEBUG
        print("_onGlassesConnected----arguments----\(glasses)------")
        #endif

        
        DispatchQueue.main.async {
            self.connectedGlasses = glasses
            self.connectedGlasses?.isConnected = true
            self.isConnecting = false
        }
        
        Task {
            await startSendBeatHeart()
            //_ = await BleManager.shared.setWearDetectionEnabled(isEnabled: false)
        }
        
      
    }
    
    private var tryTime = 0
        
    func startSendBeatHeart(sendImmediately: Bool = true) async {
        
        stopSendBeatHeart()
        if (sendImmediately == true) {
            await self.sendHeartBeatWithRetry()
        }
        
        let timer = DispatchSource.makeTimerSource(queue: bleQueue)
        timer.schedule(deadline: .now() + 8, repeating: 8)
        timer.setEventHandler { [weak self] in
            Task {
                await self?.sendHeartBeatWithRetry()
            }
        }
        
        timer.resume()
        heartbeatSource = timer
    }

    private func sendHeartBeatWithRetry() async {
            let isSuccess = await Proto.sendHeartBeat()
            if !isSuccess && self.tryTime < 2 {
                self.tryTime += 1
                _ = await Proto.sendHeartBeat()
            } else {
                self.tryTime = 0
            }
        }
    
//    func safeSendHeartbeat(timeoutMs: Int = 2000) async -> Bool {
//        do {
//            _ = try await withTimeout(milliseconds: timeoutMs) {
//                return await Proto.sendHeartBeat()
//            }
//        } catch {
//            print("Heartbeat timeout or failure: \(error)")
//            // You can optionally retry or restart BLE
//        }
//        return false
//    }

//    func withTimeout<T>(milliseconds: Int, _ operation: @escaping () async throws -> T) async throws -> T {
//        try await withThrowingTaskGroup(of: T.self) { group in
//            group.addTask {
//                try await operation()
//            }
//            group.addTask {
//                try await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
//                throw TimeoutError()
//            }
//
//            let result = try await group.next()!
//            group.cancelAll()
//            return result
//        }
//    }

    struct TimeoutError: Error {}
    
    
    func turnDisplayOnOrOff(_ isOn: Bool, depth: Int, height: Int) async -> Bool {
        
        assert((0x00...0x08).contains(height), "Height must be 0x00 to 0x08")
        assert((0x01...0x09).contains(depth), "Depth must be 0x01 to 0x09")
        
        
//        Turn the display on?
//        sent status 39  L 0 , sent size: 5  sent: 39 05 00 69 01
//        sent status 39  R 0 , sent size: 5  sent: 39 05 00 69 01
//        sent status 50  R 0 , sent size: 6  sent: 50 06 00 00 01 01
//        sent status 26  L 0 , sent size: 8  sent: 26 08 00 08 02 01 07 04
//        sent status 26  R 0 , sent size: 8  sent: 26 08 00 08 02 01 07 04

        
        let commands: [Data] = [
            Data([0x39, 0x05, 0x00, 0x69, isOn ? 0x01 : 0x00]),
            Data([0x50, 0x06, 0x00, 0x00, 0x01, isOn ? 0x01 : 0x00]),
            Data([0x26, 0x08, 0x00, 0x08, 0x02, isOn ? 0x01 : 0x00, UInt8(height), UInt8(depth)])
        ]

        var allSuccess = true

        for command in commands {
            let firstByte = command.first ?? 0x00
            if firstByte == 0x39 || firstByte == 0x26 {
                let successL = await requestRetry(command, lr: GlassLensSide.Left, timeoutMs: 500)
                let successR = await requestRetry(command, lr: GlassLensSide.Right, timeoutMs: 500)
                if successL.isTimeout || successR.isTimeout {
                    allSuccess = false
                }
            } else {
                let response = await requestRetry(command, lr: GlassLensSide.Right, timeoutMs: 500)
                if response.isTimeout {
                    allSuccess = false
                }
            }
        }

        #if DEBUG
        print("turnDisplayOn result: \(allSuccess)")
        #endif

        return allSuccess
    }

    
    func onGlassesDisconnected() {
        DispatchQueue.main.async {
            self.isConnecting = false
            self.connectedGlasses = nil
        }
            stopSendBeatHeart()
        }
    
    func stopSendBeatHeart() {
        heartbeatSource?.cancel()
        heartbeatSource = nil
    }
    
    // MARK: - Listener Start
    func startListening() {
        
        bleCancellable = BluetoothManager.shared.bleEventPublisher
                .sink { res in
                    BleManager.shared.handleReceivedData(res)
                }
    }
}

    
extension BleManager{
    
    func handleReceivedData(_ res: GlassesResponse) {
        if res.type == "VoiceChunk" { return }

        let cmd = "\(res.lr.rawValue)\(String(format: "%02x", res.data.getCmd()))"
        print("📥 Received data for cmd: \(cmd)")
        if res.data.getCmd() != 0xf1 {
            print("\(Date()) BleManager receive cmd: \(cmd), len: \(res.data.count), data = \(res.data.hexString)")
        }

        if res.data.getCmd() == 0xF5 {
            let subCommand = res.data.count > 1 ? Int(res.data[1]) : 0x00
            handleDeviceEvent(subCommand: subCommand, payload: res.data, lr: res.lr)
            return
        }

        
        bleQueue.async {
                        if let cont = self.reqListen.removeValue(forKey: cmd) {
                            self.reqTimeout[cmd]?.invalidate()
                            self.reqTimeout.removeValue(forKey: cmd)
                            cont.resume(returning: res)
                        } else if let next = self.nextReceive {
                            self.nextReceive = nil
                            next.resume(returning: res)
                        }
                    }
    }

    func lR() -> GlassLensSide {
        if BleManager.shared.isBothConnected() {
            return GlassLensSide.Right
        }
        return GlassLensSide.Left
    }
    
    func request(
        _ data: Data,
        lr: GlassLensSide,
        timeoutMs: Int = 1000,
        useNext: Bool = false
    ) async -> GlassesResponse {
            let lrVal = lr
        let cmd = "\(lrVal.rawValue)\(String(format: "%02x", data.getCmd()))"

            return await withCheckedContinuation { (cont: CheckedContinuation<GlassesResponse, Never>) in
                if useNext {
                    nextReceive = cont
                } else {
                    bleQueue.async {
                        if let old = self.reqListen.removeValue(forKey: cmd) {
                            let timeoutResult = GlassesResponse(lr: lr, isTimeout: true)
                        old.resume(returning: timeoutResult)
                        print("already exist key: \(cmd)")
                            self.reqTimeout[cmd]?.invalidate()
                        }
                        self.reqListen[cmd] = cont
                    }
                }

                if timeoutMs > 0 {
                    if timeoutMs > 0 {
                        let timer = Timer.scheduledTimer(withTimeInterval: Double(timeoutMs) / 1000.0, repeats: false) { [weak self] _ in
                            bleQueue.async {
                                self?.checkTimeout(cmd: cmd, timeoutMs: timeoutMs, data: data, lr: lrVal)
                            }
                        }
                        bleQueue.async {
                            self.reqTimeout[cmd] = timer
                        }
                    }
                }

                    BluetoothManager.shared.writeData(writeData: data, lr: lrVal)//sendData(data, lr: lrVal)
            }
        }

    private func checkTimeout(cmd: String, timeoutMs: Int, data: Data, lr: GlassLensSide) {
            bleQueue.async {
                    if let cont = self.reqListen.removeValue(forKey: cmd) {
                        let timeoutResult = GlassesResponse(lr:lr, isTimeout: true)
                        print("Timeout \(cmd) of \(timeoutMs)")
                        cont.resume(returning: timeoutResult)
                    }
                    self.reqTimeout[cmd]?.invalidate()
                    self.reqTimeout.removeValue(forKey: cmd)
                }
        }

    func requestRetry(
        _ data: Data,
        lr: GlassLensSide,
        timeoutMs: Int = 200,
        retry: Int = 3,
        useNext: Bool = false
    ) async -> GlassesResponse {
        for _ in 0...retry {
            let result = await request(data, lr: lr, timeoutMs: timeoutMs, useNext: useNext)
            if !result.isTimeout {
                return result
            }
            if !isBothConnected() {
                break
            }
        }
        return GlassesResponse(lr: lr, isTimeout: true)
    }

//    func sendData(
//        _ data: Data,
//        lr: String
//    ) async {
//            return BluetoothManager.shared.writeData(writeData: data, lr: lr)
//    }

    func isBothConnected() -> Bool {
        return true // TODO: Add real check if needed
    }
}


extension Data {
    var hexString: String {
        self.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}


extension BleManager {
    
//    func sendBmpData(_ bmpData: Data) async -> Bool {
//        // Queue the new BMP
//        _pendingBmp = bmpData
//        
//        // If a send is already in progress, just return false for now
//        guard !_isSendingBmp else { return false }
//        
//        // Process the queue
//        return await _processBmpQueue()
//    }
    
    // MARK: - Completion handler version (background-safe)
    func sendBmpData(_ bmpData: Data, completion: @escaping (Bool) -> Void) {
        // Queue the new BMP
        _pendingBmp = bmpData
        
        // If a send is already in progress, just call completion(false)
        guard !_isSendingBmp else {
            completion(false)
            return
        }
        
        _processBmpQueueSafe(completion: completion)
    }

    private func _processBmpQueueSafe(completion: @escaping (Bool) -> Void) {
        bleQueue.async { [weak self] in
            guard let self = self else { return }
            Task {
                let success = await self._processBmpQueue()
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }

    private func _processBmpQueue() async -> Bool {
        guard !_isSendingBmp else { return false }
        
        _isSendingBmp = true
        var overallSuccess = true
        
        while let current = _pendingBmp {
            _pendingBmp = nil // Clear for next frame
            print("Sending BMP...")
            
            let success = await _sendBmpData(current)
            overallSuccess = overallSuccess && success
            
            print("BMP send done: \(success)")
        }
        
        _isSendingBmp = false
        return overallSuccess
    }
    

//    func _sendBmpData(_ bmpData: Data) async -> Bool {
//
//        let initialSeq = 0
////        let _ = await Proto.sendHeartBeat()
////        print("\(Date()) testBMP -------startSendBeatHeart----isSuccess---\(isSuccess)------")
////
//        await BleManager.shared.startSendBeatHeart(sendImmediately: false)
//
//        async let leftResult = updateBmp(lr: GlassLensSide.Left, image: bmpData, seq: initialSeq)
//        async let rightResult = updateBmp(lr: GlassLensSide.Right, image: bmpData, seq: initialSeq)
//        let results = await [leftResult, rightResult]
////        let leftResult = await updateBmp(lr: GlassLensSide.Left, image: bmpData, seq: initialSeq)
////        let rightResult = await updateBmp(lr: GlassLensSide.Right, image: bmpData, seq: initialSeq)
////
////        let results = [leftResult, rightResult]
//
//        let successL = results[0]
//        let successR = results[1]
//
//        if successL {
//            print("\(Date()) left ble success")
//        } else {
//            print("\(Date()) left ble fail")
//        }
//
//        if successR {
//            print("\(Date()) right ble success")
//        } else {
//            print("\(Date()) right ble fail")
//        }
//        return successL && successR
//    }
    
    func _sendBmpData(_ bmpData: Data) async -> Bool {
        await BleManager.shared.startSendBeatHeart(sendImmediately: false)

        // Phase 1: Send packets to both in parallel
        async let leftSend = sendBmpPackets(lr: .Left, image: bmpData)
        async let rightSend = sendBmpPackets(lr: .Right, image: bmpData)
        let sendResults = await [leftSend, rightSend]

        guard sendResults[0], sendResults[1] else {
            print("Packet sending failed on one side")
            return false
        }

        // Phase 2: Only after both sides done, run final confirmation
        async let leftConfirm = finalizeBmp(lr: .Left, image: bmpData)
        async let rightConfirm = finalizeBmp(lr: .Right, image: bmpData)
        let confirmResults = await [leftConfirm, rightConfirm]

        let successL = confirmResults[0]
        let successR = confirmResults[1]

        if successL { print("Left confirmation success") } else { print("Left confirmation failed") }
        if successR { print("Right confirmation success") } else { print("Right confirmation failed") }

        return successL && successR
    }
    
    // Phase 1: Only send BMP packets (no finish/CRC yet)
    private func sendBmpPackets(lr: GlassLensSide, image: Data, seq: Int? = nil) async -> Bool {
        func isOldSendPackError(currentSeq: Int?) -> Bool {
            let oldSendError = (seq == nil && currentSeq != nil)
            if oldSendError {
                print("BmpUpdate -> sendBmpPackets: old pack send error, seq = \(currentSeq!)")
            }
            return oldSendError
        }

        let packLen = 194
        var multiPacks: [Data] = []
        var i = 0
        while i < image.count {
            let end = min(i + packLen, image.count)
            let singlePack = image.subdata(in: i..<end)
            multiPacks.append(singlePack)
            i += packLen
        }

        print("BmpUpdate -> sendBmpPackets: start sending \(multiPacks.count) packs")

        for index in 0..<multiPacks.count {
            if isOldSendPackError(currentSeq: seq) { return false }
            if let seqVal = seq, index < seqVal { continue }

            let pack = multiPacks[index]
            let prefix: [UInt8] = index == 0 ? [0x15, UInt8(index & 0xff), 0x00, 0x1c, 0x00, 0x00]
                                             : [0x15, UInt8(index & 0xff)]
            let data = prefix + pack

            BluetoothManager.shared.writeData(writeData: Data(data), lr: lr)

    #if os(iOS)
            try? await Task.sleep(nanoseconds: 8_000_000)
    #else
            try? await Task.sleep(nanoseconds: 5_000_000)
    #endif
        }

        print("BmpUpdate -> sendBmpPackets finished for \(lr)")
        return true
    }

    
    private func finalizeBmp(lr: GlassLensSide, image: Data) async -> Bool {
        var currentRetryTime = 0
        let maxRetryTime = 10

        func finishUpdate() async -> Bool {
            if currentRetryTime >= maxRetryTime {
                return false
            }

            let ret = await BleManager.shared.request(Data([0x20, 0x0d, 0x0e]), lr: lr, timeoutMs: 5000)
            if ret.isTimeout {
                currentRetryTime += 1
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                return await finishUpdate()
            }
            return ret.data.count > 1 && ret.data[1] == 0xc9
        }

        let isSuccess = await finishUpdate()
        guard isSuccess else { return false }

        let result = prependAddress(image: image)
        let crc = calculateCRC32(data: result)

        let ret = await BleManager.shared.request(Data([0x16] + crc), lr: lr, timeoutMs: 5000)

        return ret.data.count > 5 && ret.data[5] == 0xCA
    }
    
    
    func clearGlasses() async -> Bool {
        print("send exit all func")
        let data: [UInt8] = [0x18]

        let retL = await BleManager.shared.request(Data(data), lr: GlassLensSide.Left, timeoutMs: 1500)

        print("\(Date()) exit----L----ret---\(retL.data as NSData)--")

        if retL.isTimeout {
            return false
        } else if retL.data.count > 1, retL.data[1] == 0xc9 {
            let retR = await BleManager.shared.request(Data(data), lr: GlassLensSide.Right, timeoutMs: 1500)

            print("\(Date()) exit----R----retR---\(retR.data as NSData)--")

            if retR.isTimeout {
                return false
            } else if retR.data.count > 1, retR.data[1] == 0xc9 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
//    private func updateBmp(lr: GlassLensSide, image: Data, seq: Int? = nil) async -> Bool {
//
//        func isOldSendPackError(currentSeq: Int?) -> Bool {
//            let oldSendError = (seq == nil && currentSeq != nil)
//            if oldSendError {
//                print("BmpUpdate -> updateBmp: old pack send error, seq = \(currentSeq!)")
//            }
//            return oldSendError
//        }
//
//        let packLen = 194
//        var multiPacks: [Data] = []
//        var i = 0
//        while i < image.count {
//            let end = min(i + packLen, image.count)
//            let singlePack = image.subdata(in: i..<end)
//            multiPacks.append(singlePack)
//            i += packLen
//        }
//
//        print("BmpUpdate -> updateBmp: start sending \(multiPacks.count) packs")
//
//        for index in 0..<multiPacks.count {
//            if isOldSendPackError(currentSeq: seq) { return false }
//            if let seqVal = seq, index < seqVal { continue }
//
//            let pack = multiPacks[index]
//            let prefix: [UInt8] = index == 0 ? [0x15, UInt8(index & 0xff), 0x00, 0x1c, 0x00, 0x00] : [0x15, UInt8(index & 0xff)]
//            let data = prefix + pack
//
//            print("\(Date()) updateBmp----data---*\(data.count)---*\(data)----------")
//
//            BluetoothManager.shared.writeData(writeData: Data(data), lr: lr)
//
//#if os(iOS)
//            try? await Task.sleep(nanoseconds: 8_000_000)
//#else
//            try? await Task.sleep(nanoseconds: 5_000_000)
//#endif
//
//            var offset = index * packLen
//            if offset > image.count - packLen {
//                offset = image.count - pack.count
//            }
//            //_onProgressCall(lr: lr, offset: offset, index: index, total: image.count)
//        }
//
//        if isOldSendPackError(currentSeq: seq) { return false }
//
//        var currentRetryTime = 0
//        let maxRetryTime = 10
//
//        func finishUpdate() async -> Bool {
//            print("\(Date()) finishUpdate----currentRetryTime-----\(currentRetryTime)-----maxRetryTime-----\(maxRetryTime)--")
//            if currentRetryTime >= maxRetryTime {
//                return false
//            }
//
//            let ret = await BleManager.shared.request(Data([0x20, 0x0d, 0x0e]), lr: lr, timeoutMs: 5000)
//            print("\(Date()) finishUpdate---lr---\(lr)--ret----\(ret.data)-----")
//            if ret.isTimeout {
//                currentRetryTime += 1
//                try? await Task.sleep(nanoseconds: 1_000_000_000)
//                return await finishUpdate()
//            }
//            return ret.data.count > 1 && ret.data[1] == 0xc9
//        }
//
//        print("\(Date()) updateBmp-------------over------")
//
//        let isSuccess = await finishUpdate()
//
//        print("\(Date()) finishUpdate--isSuccess----*\(isSuccess)-")
//        guard isSuccess else {
//            print("finishUpdate result error lr: \(lr)")
//            return false
//        }
//
//        print("finishUpdate result success lr: \(lr)")
//
//        let result = prependAddress(image: image)
//        let crc = calculateCRC32(data: result)
//
//        let ret = await BleManager.shared.request(Data([0x16] + crc), lr: lr, timeoutMs: 5000)
//
//        print("\(Date()) Crc32Xz---lr---\(lr)---ret--------\(ret.data)------crc----\(crc)--")
//
//        //if ret.data.count > 5 && ret.data[5] != 0xc9 {
//        if ret.data.count > 5 && ret.data[5] != 0xCA {
//            print("CRC checks failed...")
//            return false
//        }
//
//        return true
//    }
    
//    private func _onProgressCall(lr: GlassLensSide, offset: Int, index: Int, total: Int) {
//        let progress = (Double(offset) / Double(total)) * 100.0
//        print("\(Date()) BmpUpdate -> Progress: \(lr) \(String(format: "%.2f", progress))%, index: \(index)")
//    }

    private func prependAddress(image: Data) -> Data {
        let addressBytes: [UInt8] = [0x00, 0x1c, 0x00, 0x00]
        return Data(addressBytes + image)
    }

    private func calculateCRC32(data: Data) -> [UInt8] {
        // Using CRC32-ISO-HDLC which is closest to Dart's `Crc32Xz()`
        var crc: UInt32 = 0xffffffff
        for byte in data {
            crc ^= UInt32(byte) << 24
            for _ in 0..<8 {
                crc = (crc & 0x80000000 != 0) ? (crc << 1) ^ 0x04C11DB7 : (crc << 1)
            }
        }
        crc = crc ^ 0xffffffff
        return [
            UInt8((crc >> 24) & 0xff),
            UInt8((crc >> 16) & 0xff),
            UInt8((crc >> 8) & 0xff),
            UInt8(crc & 0xff)
        ]
    }

    /// Send the same data to both left and right devices, with retries and success validation
    func sendBoth(
        _ data: Data,
        timeoutMs: Int = 250,
        retry: Int = 0,
        isSuccess: ((Data) -> Bool)? = nil
    ) async -> Bool {
        
        let retL = await requestRetry(data, lr: GlassLensSide.Left, timeoutMs: timeoutMs, retry: retry)
        if retL.isTimeout {
            print("sendBoth L timeout")
            return false
        }
        if let successCheck = isSuccess, !successCheck(retL.data) {
            return false
        }
        
        let retR = await requestRetry(data, lr: GlassLensSide.Right, timeoutMs: timeoutMs, retry: retry)
        if retR.isTimeout {
            return false
        }
        if let successCheck = isSuccess {
            return successCheck(retR.data)
        }
        
        if retL.data.count > 1, retL.data[1] == 0xC9 {
            let ret = await requestRetry(data, lr: GlassLensSide.Right, timeoutMs: timeoutMs, retry: retry)
            if ret.isTimeout { return false }
        }
        return true
    }
    
    /// Send a list of data packets sequentially to one or both devices
    func requestList(
        _ sendList: [Data],
        lr: GlassLensSide,
        timeoutMs: Int? = nil
    ) async -> Bool {
            return await _requestList(sendList, lr: lr, timeoutMs: timeoutMs)
    }
    
    private func _requestList(
        _ sendList: [Data],
        lr: GlassLensSide,
        keepLast: Bool = false,
        timeoutMs: Int? = nil
    ) async -> Bool {
        let len = keepLast ? sendList.count - 1 : sendList.count
        for i in 0..<len {
            let pack = sendList[i]
            let resp = await request(pack, lr: lr, timeoutMs: timeoutMs ?? 350)
            if resp.isTimeout {
                return false
            }
            if resp.data.count > 1, resp.data[1] != 0xC9 && resp.data[1] != 0xCB {
                return false
            }
        }
        return true
    }
    
    // MARK: - Brightness
    
    /// Set brightness level (0...42) and auto/manual flag, only to Right device ("R")
    func setBrightness(
        brightnessLevel: Int,
        autoBrightness: Bool
    ) async -> Bool {
        let brightness = min(max(brightnessLevel, 0), 42)
        let auto = autoBrightness ? 0x01 : 0x00
        let data = Data([0x01, UInt8(brightness), UInt8(auto)])
        let response = await request(data, lr: GlassLensSide.Right)
        
        print("Sent brightness command: \(data.hexString)")
        print("Received response: \(response.data.hexString)")
        
        return !response.isTimeout
    }
    
    /// Get brightness settings from Right device ("R")
    func getBrightness() async -> (brightness: Int, auto: Bool)? {
        let requestData = Data([0x29])
        let response = await requestRetry(requestData, lr: GlassLensSide.Right, timeoutMs: 500, retry: 2)
        
        if response.isTimeout {
            print("getBrightnessRightArm: Request timed out.")
            return nil
        }
        
        let data = response.data
        if data.count >= 4, data[0] == 0x29 {
            let brightness = Int(data[2])
            let isAuto = data[3] == 0x01
            return (brightness, isAuto)
        } else {
            print("getBrightnessRightArm: Invalid response: \(data.hexString)")
            return nil
        }
    }
    
    func getSilentMode() async -> Bool? {
        let command = Data([0x2B])

        let responseL = await requestRetry(command, lr: GlassLensSide.Left, timeoutMs: 500)
        let responseR = await requestRetry(command, lr: GlassLensSide.Right, timeoutMs: 500)

        func parseSilentMode(from data: Data) -> Bool? {
            guard data.count >= 3 else { return nil }
            switch data[2] {
            case 0x0C: return true  // Silent Mode ON
            case 0x0A: return false // Silent Mode OFF
            default: return nil     // Unexpected value
            }
        }

        // Prefer Right arm response, fallback to Left
        return parseSilentMode(from: responseR.data) ?? parseSilentMode(from: responseL.data)
    }
    
    func getSerialNumber() async -> GlassSerialNumber? {
        let command = Data([0x34])
        
        let responseL = await requestRetry(command, lr: GlassLensSide.Left, timeoutMs: 500)
        let responseR = await requestRetry(command, lr: GlassLensSide.Right, timeoutMs: 500)

        let parsed = GlassSerialNumber(from: responseR.data) ?? GlassSerialNumber(from: responseL.data)

        if let serial = parsed {
                if let connected = BleManager.shared.connectedGlasses {
                    connected.serialNumber = serial
                }
        }

        return parsed
    }

    func getArmsInfo() async -> (left: ArmInfo?, right: ArmInfo?) {
        let packet = Data([0x2C, 0x01])

        let leftResponse = await requestRetry(packet, lr: GlassLensSide.Left, timeoutMs: 500)
        let rightResponse = await requestRetry(packet, lr: GlassLensSide.Right, timeoutMs: 500)

        var leftArmInfo: ArmInfo?
        var rightArmInfo: ArmInfo?

            if !leftResponse.isTimeout {
                leftArmInfo = ArmInfo(side: GlassLensSide.Left, data: leftResponse.data)
                    BleManager.shared.connectedGlasses?.leftArmInfo = leftArmInfo
            }
            if !rightResponse.isTimeout {
                rightArmInfo = ArmInfo(side: GlassLensSide.Right, data: rightResponse.data)
                    BleManager.shared.connectedGlasses?.rightArmInfo = rightArmInfo
            }

        return (left: leftArmInfo, right: rightArmInfo)
    }

    
    func setSilentMode(isOn: Bool) async -> Bool? {
        let subCommand: UInt8 = isOn ? 0x0C : 0x0A
                let command = Data([0x03, subCommand])

                let success = await sendBoth(
                    command,
                    timeoutMs: 500,
                    retry: 2,
                    isSuccess: { data in
                        // Accept any 0x03 response with 0xC9 or 0xCB success codes
                        return data.count >= 2 &&
                               data[0] == 0x03 &&
                               (data[1] == 0xC9 || data[1] == 0xCB)
                    }
                )

                if success {
                    print("✅ Silent Mode \(isOn ? "Enabled" : "Disabled") on both arms")
                } else {
                    print("❌ Failed to set Silent Mode \(isOn ? "ON" : "OFF")")
                }

                return success
    }
    
    func getIsWearDetectionEnabled() async -> Bool? {
        let command = Data([0x3A])
        
        let responseR = await requestRetry(command, lr: GlassLensSide.Right, timeoutMs: 500)

        func parseWearDetection(from data: Data) -> Bool? {
            guard data.count >= 3 else { return nil }
            switch data[2] {
            case 0x01: return true   // Worn (detected on face)
            case 0x00: return false  // Not worn
            default: return nil      // Unexpected value
            }
        }
        return parseWearDetection(from: responseR.data)
    }
    
    func setWearDetectionEnabled(isEnabled: Bool) async -> Bool? {
        let subCommand: UInt8 = isEnabled ? 0x01 : 0x00  // 0x01 = enable, 0x00 = disable
            let command = Data([0x27, subCommand])     // Command 0x27

            let success = await sendBoth(
                command,
                timeoutMs: 500,
                retry: 2,
                isSuccess: { data in
                    // Accept any 0x27 response as generic success
                    return data.count >= 2 &&
                           data[0] == 0x27 &&
                           (data[1] == 0xC9 || data[1] == 0xCB)
                }
            )

            if success {
                print("✅ Wear Detection \(isEnabled ? "Enabled" : "Disabled") on both arms")
            } else {
                print("❌ Failed to set Wear Detection \(isEnabled ? "ON" : "OFF")")
            }

            return success
    }
    
    // MARK: - Display depth and height
    
    /// Get display depth and height from Right device ("R")
    func getDisplayDepthAndHeight() async -> (height: Int, depth: Int)? {
        let requestData = Data([0x3B])
        let response = await requestRetry(requestData, lr: GlassLensSide.Right, timeoutMs: 500, retry: 2)
        
        if response.isTimeout {
            print("getDisplaySettings: Request timed out.")
            return nil
        }
        
        let data = response.data
        if data.count >= 4, data[0] == 0x3B, data[1] == 0xC9 {
            let height = Int(data[2])
            let depth = Int(data[3])
            guard (0x00...0x08).contains(height), (0x01...0x09).contains(depth) else {
                print("getDisplaySettings: Invalid values height: \(height), depth: \(depth)")
                return nil
            }
            return (height, depth)
        } else {
            print("getDisplaySettings: Invalid response data: \(data.hexString)")
            return nil
        }
    }
    
    /// Set display depth and height (height: 0x00–0x08, depth: 0x01–0x09)
    func setDisplayDepthAndHeight(
            height: Int,
            depth: Int,
            delaySeconds: Int = 3,
            retryCount: Int = 2
        ) async -> Bool {
            assert((0x00...0x08).contains(height), "Height must be between 0x00 and 0x08")
            assert((0x01...0x09).contains(depth), "Depth must be between 0x01 and 0x09")

            var seqCounter = 0
            let seq = UInt8(seqCounter & 0xFF)
            seqCounter = (seqCounter + 1) % 256

            func buildPacket(preview: UInt8) -> Data {
                return Data([
                    0x26, // Header
                    0x08, // Packet size
                    0x00, // Pad
                    seq,  // Sequence number
                    0x02, // Fixed
                    preview, // Preview flag
                    UInt8(height),
                    UInt8(depth)
                ])
            }

            func isSuccess(_ value: Data) -> Bool {
                #if DEBUG
                print("Response Received: \(value.hexString)")
                #endif
                return value.count >= 6 &&
                       value[0] == 0x26 &&
                       value[1] == 0x06 &&
                       value[4] == 0x02 &&
                       value[3] == seq &&
                       (value[5] == 0xC9 || value[5] == 0xCA)
            }

            let previewPacket = buildPacket(preview: 0x01)
            let finalPacket = buildPacket(preview: 0x00)

            let previewSuccess = await BleManager.shared.sendBoth(
                previewPacket,
                timeoutMs: 1000,
                retry: retryCount,
                isSuccess: isSuccess
            )

            if !previewSuccess {
                #if DEBUG
                print("Preview ON failed")
                #endif
                return false
            }

            try? await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)

            let finalSuccess = await BleManager.shared.sendBoth(
                finalPacket,
                timeoutMs: 1000,
                retry: retryCount,
                isSuccess: isSuccess
            )

            if !finalSuccess {
                #if DEBUG
                print("Preview OFF failed")
                #endif
            }

            return finalSuccess
        }
}


extension BleManager {
    func handleDeviceEvent(subCommand: Int, payload: Data, lr: GlassLensSide) {
        if #available(iOS 14.0, *) {
            print("handleDeviceEvent: subCommand = 0x\(String(format: "%02X", subCommand)), payload = \(payload.hexString)")
        }
        
        switch subCommand {
        case 0x00:
            // TouchPad Double Tap
            break
            
        case 0x01:
            // TouchPad Single Tap
            // Example: trigger actions based on side
            // if lr == "L" { EvenAI.get.lastPageByTouchpad() } else { EvenAI.get.nextPageByTouchpad() }
            break
            
        case 0x02:
            print("Event: Head Up")
            
        case 0x03:
            print("Event: Head Down")
            
        case 0x04:
            print("Event: Triple Tap (1)")
            
        case 0x05:
            print("Event: Triple Tap (2)")
            
        case 0x06:
            print("Event: Glasses are worn")
            DispatchQueue.main.async {
                self.connectedGlasses?.glassStatus = .glassesWorn
            }
        case 0x07:
            print("Event: Glasses taken off (not in box)")
            DispatchQueue.main.async {
                self.connectedGlasses?.glassStatus = .glassestNotWorn
            }
        case 0x08:
            print("Event: Glasses in case, lid open")
            DispatchQueue.main.async {
                self.connectedGlasses?.glassStatus = .glassesInCaseLidOpen
            }
            
        case 0x09:
            if payload.count > 2 {
                DispatchQueue.main.async {
                    self.connectedGlasses?.glassCharging = (payload[1] == 0x01)
                }
                print("Event: Glasses charging status: \(connectedGlasses?.glassCharging == true ? "Charging" : "Not Charging")")
            } else {
                print("Event: Glasses charging status: Unknown")
            }
            
        case 0x0A:
            print("Event: 0x0A")
            
        case 0x0C:
            print("Event: 0x0C")
            
        case 0x0D:
            print("Event: 0x0D")
            
        case 0x10:
            print("Event: Reserved event 0x\(String(format: "%02X", subCommand))")
            
        case 0x0B:
            print("Event: Glasses in case, lid closed")
            DispatchQueue.main.async {
                self.connectedGlasses?.glassStatus = .glassesInCaseLidClosed
            }
            
        case 0x0E:
            if payload.count > 2 {
                DispatchQueue.main.async {
                    self.connectedGlasses?.caseCharging = (payload[1] == 0x01)
                }
                print("Event: Case Charging Status: \(connectedGlasses?.caseCharging == true ? "Charging" : "Not Charging")")
            } else {
                print("Event: Case Charging Status: Unknown")
            }
            
        case 0x0F:
            if payload.count > 2 {
                let battery = Int(payload[2])
                DispatchQueue.main.async {
                    self.connectedGlasses?.caseBatteryCharge = battery
                }
                print("Event: Case Battery: \(battery)%")
            } else {
                print("Event: Case Battery: ?%")
            }
            
        case 0x11:
            print("Event: BLE Paired Successfully")
                
//            if connectedGlasses?.leftDevice.state == .connected && connectedGlasses?.rightDevice.state == .connected {
//                        DispatchQueue.main.async {
//                            self.connectedGlasses?.isConnected = true
//                            self.isConnecting = false
//                    }
//                }
            
            
        case 0x12:
            print("Event: Right TouchPad tap-and-hold sequence")
            
        case 0x17:
            print("Event: Left TouchPad Held")
            
        case 0x18:
            print("Event: Left TouchPad Released")
            
        case 0x1E:
            print("Event: Open Dashboard")
//            DispatchQueue.main.async {
//                self.connectedGlasses?.dashboardOpen = true
//            }
            
        case 0x1F:
            print("Event: Close Dashboard")
            DispatchQueue.main.async {
                self.connectedGlasses?.dashboardOpen = false
            }
            
        case 0x20:
            print("Event: Double Tap for Translate/Transcribe")
            
        case 0x23:
            // EvenAI start event - call related functions if needed
            break
            
        case 0x24:
            // EvenAI record over event - call related functions if needed
            break
            
        default:
            print("Unknown Device Event: 0x\(String(format: "%02X", subCommand))")
        }
        
//        notifyListeners()
    }
}
