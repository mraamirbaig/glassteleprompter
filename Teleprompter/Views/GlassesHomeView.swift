//
//  GlassesHomeView.swift
//  Teleprompter
//
//  Created by abaig on 02/07/2025.
//

import SwiftUI
import Combine

struct GlassesHomeView: View {
    
    private let commonSpace: CGFloat = 12.0
    @State private var showConnectGlassesBottomSheetView = false
    @StateObject private var bleManager = BleManager.shared
    
    @State private var glassesDisplayOn = false
    @State private var glassesBrightness: Double = 0
    @State private var autoBrightness: Bool? = nil
    @State private var height: Double = 0
    @State private var depth: Double = 1
    @State private var silentMode: Bool? = nil
    @State private var leftArmInfo: ArmInfo? = nil
    @State private var rightArmInfo: ArmInfo? = nil
    @State private var currentGlassStatus: GlassesStatus = .glassestNotWorn
    
    @State private var path = NavigationPath()
    
//    private func requestNotificationAuthorization() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//                   if granted {
//                       print("Notification permission granted")
//                   } else if let error = error {
//                       print("Error requesting notification permission: \(error)")
//                   }
//               }
//    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: commonSpace) {
                Group {
                    if bleManager.connectedGlasses?.isConnected == true {
                        glassesDisplayView()
                            .onAppear {
                                loadDisplayDepthAndHeight()
                                loadBrightnessSettings()
                                loadSilentMode()
                                loadArmInfo()
//                                loadGlassDisplayOn()
//                                requestNotificationAuthorization()
                            }
                    }else if bleManager.isConnecting {
                        connectingView
                    } else {
                        searchGlassesView()
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.3)
                HStack(spacing: commonSpace) {
                    connectedWidget().background(Color.black)
                    brightnessAndSilentButtonWidget().background(Color.black)
                }
                .frame(height: UIScreen.main.bounds.height * 0.2)
                teleprompterView()
                Spacer()
            }
            .padding(commonSpace)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .navigationBarTitle("Teleprompter", displayMode: .inline)
            .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .dashboard:
                        DashboardView()
                    case .glassSettings:
                        GlassSettingsPage(path: $path)
                    }
                }
            
        }.navigationBarTitleDisplayMode(.inline)
            .tint(.white)
        .sheet(isPresented: $showConnectGlassesBottomSheetView) {
            ConnectGlassesBottomSheetView(dismissAction: {
                showConnectGlassesBottomSheetView = false
                    })    .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                }
        .onReceive(
            bleManager.$connectedGlasses
                .compactMap { $0 }
                .flatMap { $0.$dashboardOpen }
        ) { newDashboardOpen in
            glassesDisplayOn = newDashboardOpen
        }
        .onReceive(
            bleManager.$connectedGlasses
                .compactMap { $0 }
                .flatMap { $0.$glassStatus }
        ) { newStatus in
            currentGlassStatus = newStatus
        }
    }
    
    private var connectingView: some View {
        VStack {
            Spacer()
            Image("glasses_not_worn")
                .resizable()
                .scaledToFit()
            Text("Connecting with the following Even G1 Glasses:")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            HStack(spacing: 8) {
                ProgressView()
                Text("SN \(BluetoothManager.shared.currentConnectingGlasses?.serialNumber.fullSerial ?? "N/A")")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            Spacer()
        }.padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
    
    func teleprompterView() -> some View {
        NavigationLink(value: Route.dashboard) {
            HStack {
                Text("Teleprompter")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .opacity(bleManager.connectedGlasses?.isConnected == true ? 1 : 0.4)
            .padding(.vertical)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color.black)
//            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        
        .disabled(bleManager.connectedGlasses?.isConnected != true)
    }

    
    func searchGlassesView() -> some View {
        VStack {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "bolt.horizontal.fill") // Alternative to bluetooth_disabled_outlined
                    .foregroundColor(.white)
                Text("No Paired Even G1")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            Text("Press here to search")
                .foregroundColor(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .onTapGesture {
            showConnectGlassesBottomSheetView = true// You need to implement this bridge
        }
    }
    
    @ViewBuilder
    func glassesDisplayView() -> some View {
        if silentMode ?? false {
            silentModeDisplayView()
        } else {
            glassDisplayOnOrOffWidget()
        }
    }
    
    private func silentModeDisplayView() -> some View {
        ZStack {
                    Color.black.edgesIgnoringSafeArea(.all) // optional background
                    Text("Silent Mode is active")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
    }
    
    private func glassDisplayOnOrOffWidget() -> some View {
        
        VStack(alignment: .leading) {
            HStack {
                VStack {
                    Image(systemName: "rectangle.fill.on.rectangle.fill")
                        .foregroundColor(.gray)
                        .opacity(glassesDisplayOn ? 1.0 : 0.4)
                    Slider(
                        value: $depth,
                        in: 1...9,
                        step: 1,
                        onEditingChanged: { editing in
                            if !editing {
                                Task {
                                    await BleManager.shared.setDisplayDepthAndHeight(height: Int(height), depth: Int(depth))
                                }
                            }
                        }
                    )
                    .opacity(glassesDisplayOn ? 1.0 : 0.4)
                    .disabled(!glassesDisplayOn)
                    Text("\(Int(depth))")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack {
                    Slider(
                        value: $height,
                        in: 0...8,
                        step: 1,
                        onEditingChanged: { editing in
                            if !editing {
                                Task {
                                    await BleManager.shared.setDisplayDepthAndHeight(height: Int(height), depth: Int(depth))
                                }
                            }
                        }
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(height: 120)
                    .opacity(glassesDisplayOn ? 1.0 : 0.4)
                    .disabled(!glassesDisplayOn)
                    Text("\(Int(height))")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                }
            }
            .padding()
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "display")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    Text("Display On/Off")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                Spacer()
                Toggle("", isOn: $glassesDisplayOn)
                    .labelsHidden()
                    .onChange(of: glassesDisplayOn) { _, newValue in
                        toggleDisplay(value: newValue)
                    }
            }
            .padding(.top, 8)
        }.padding()
            .background(Color.black)
    }
    
    func connectedWidget() -> some View {
        VStack {
            if bleManager.connectedGlasses?.isConnected == true {
                
                NavigationLink(value: Route.glassSettings) {
                    VStack {
                        HStack {
                            Text("My G1")
                                .foregroundColor(.white)
                            Spacer()
                            VStack {
                            if let charge = leftArmInfo?.batteryPercent ?? rightArmInfo?.batteryPercent{
                                HStack(spacing: 4) {
                                    Text("\(charge)%")
                                        .foregroundColor(.white)
                                    Image(systemName: "eyeglasses")
                                        .foregroundColor(.white)
                                }
                            }
                            if let charge = bleManager.connectedGlasses?.caseBatteryCharge {
                                HStack(spacing: 4) {
                                    Text("\(charge)%")
                                        .foregroundColor(.white)
                                    Image(systemName: "battery.100")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        }
                        createConnectGlassImage()
                    }
                }.padding(.vertical)
            } else {
                VStack {
                    Text("No Even G1")
                        .foregroundColor(.white)
                    Image("glasses_not_worn")
                        .resizable()
                        .scaledToFit()
                }
                .padding(.vertical)
            }
        }
    }
    
    @ViewBuilder
    private func createConnectGlassImage() -> some View {
            switch currentGlassStatus {
            case .glassesInCaseLidClosed:
                Image("box_lid_closed")
                    .resizable()
                    .scaledToFit()
            case .glassesInCaseLidOpen:
                Image("box_lid_open")
                    .resizable()
                    .scaledToFit()
            case .glassesWorn:
                Image("glasses_worn")
                    .resizable()
                    .scaledToFit()
            case .glassestNotWorn:
                Image("glasses_not_worn")
                    .resizable()
                    .scaledToFit()
            }
    }
    
    func brightnessWidget() -> some View {
        VStack {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.gray)
                    Text("Auto")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                Toggle("", isOn: Binding(
                    get: { autoBrightness ?? false },
                    set: { newVal in
                        autoBrightness = newVal
                        Task {
                            if newVal == false {
                                if let settings = await BleManager.shared.getBrightness() {
                                    glassesBrightness = Double(settings.brightness) / 42.0
                                }
                            }
                            let brightnessLevel = Int(glassesBrightness * 42)
                            _ = await BleManager.shared.setBrightness(brightnessLevel: brightnessLevel, autoBrightness: newVal)
                        }
                    }
                ))
                .labelsHidden()
            }
            
            Slider(
                value: $glassesBrightness,
                in: 0...1,
                step: 1/42.0,
                onEditingChanged: { editing in
                        if !editing {
                            Task {
                                let brightnessLevel = Int(glassesBrightness * 42)
                                _ = await BleManager.shared.setBrightness(brightnessLevel: brightnessLevel, autoBrightness: autoBrightness ?? false)
                            }
                        }
                    }
            )
            .disabled(autoBrightness ?? true)
            .opacity((autoBrightness ?? true) ? 0.4 : 1.0)
        }
        .padding()
        .opacity((autoBrightness == nil || silentMode == true) ? 0.4 : 1.0)
        .disabled(autoBrightness == nil || silentMode == true)
    }
    
    func brightnessAndSilentButtonWidget() -> some View {
        VStack {
            brightnessWidget()
            silentModeButtonWidget()
        }
        .opacity(bleManager.connectedGlasses?.isConnected == true && silentMode != nil ? 1 : 0.4)
        .disabled(bleManager.connectedGlasses?.isConnected != true || silentMode == nil)

    }
    
    private func silentModeButtonWidget() -> some View {
        
        Button {
            if let silentMode = silentMode {
                let newMode = !silentMode
                Task {
                    let success = await bleManager.setSilentMode(isOn: newMode)
                    if success != nil {
                        DispatchQueue.main.async {
                            self.silentMode = newMode
                        }
                    }
                }
            }
        } label: {
            
            Label("Silent Mode", systemImage: silentMode == true ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(silentMode == true ? Color.white : Color.black)
                )
                .foregroundColor(silentMode == true ? .black : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: silentMode == true ? 0 : 1)
                )
        }
        .opacity(glassesDisplayOn == true ? 0.4 : 1)
        .disabled(glassesDisplayOn == true)
    }
    
    // MARK: - Functions
    
    func loadBrightnessSettings() {
        Task {
            if bleManager.connectedGlasses?.isConnected == true {
                if let settings = await bleManager.getBrightness() {
                    DispatchQueue.main.async {
                        glassesBrightness = Double(settings.brightness) / 42.0
                        autoBrightness = settings.auto
                    }
                }
            }
        }
    }
    
    func loadDisplayDepthAndHeight() {
        Task {
            if let settings = await BleManager.shared.getDisplayDepthAndHeight() {
                //DispatchQueue.main.async {
                    height = Double(settings.height)
                    depth = Double(settings.depth)
                //}
            }
        }
    }
    
    func loadSilentMode() {
            if bleManager.connectedGlasses?.isConnected == true {
                Task {
                    if let response = await bleManager.getSilentMode() {
                        DispatchQueue.main.async {
                            silentMode = response
                        }
                    }
                }
            }

    }
    
    func loadArmInfo() {
        
            if bleManager.connectedGlasses?.isConnected == true {
                Task {
                    let response = await bleManager.getArmsInfo()
                    leftArmInfo = response.left
                    rightArmInfo = response.right
                    print("Armssssss")
                    print(response.left ?? "")
                    print(response.right ?? "")
                }
            }
    }
    
    func toggleDisplay(value: Bool) {
        Task {
            _ = await BleManager.shared.turnDisplayOnOrOff(value, depth: Int(depth), height: Int(height))
//            DispatchQueue.main.async {
//                glassesDisplayOn = value
//            }
        }
    }
}
