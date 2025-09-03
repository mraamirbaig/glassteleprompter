//
//  GlassSettingsView.swift
//  Teleprompter
//
//  Created by abaig on 02/07/2025.
//

import SwiftUI

struct GlassSettingsPage: View {
    
    @Binding var path: NavigationPath
    @State private var showDisconnectAlert = false
//    @State private var wearDetectionEnabled: Bool? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image("glasses_not_worn")
                .resizable()
                .scaledToFit()
            if let glasses = BleManager.shared.connectedGlasses,
               glasses.isConnected {
                Text("SN \(glasses.serialNumber.fullSerial)")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
//            wearDetectionWidget().onAppear {
//                loadIsWearDetectionEnabled()
//            }
            Button(action: {
                Task {
                    await resetGlasses()
                }
            }) {
                Text("Quick Restart")
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            
            Button(action: {
                showDisconnectAlert = true
            }) {
                Text("Unpair")
                    .foregroundColor(.red)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            .alert("Unpair Glasses?", isPresented: $showDisconnectAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Unpair", role: .destructive) {
                    Task {
                        await unpairGlasses()
                        path.removeLast()
                    }
                }
            } message: {
                Text("Are you sure you want to unpair the connected glasses?")
            }

            Spacer()
        }
        .padding(24)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Glasses Settings")
        .navigationBarTitleDisplayMode(.inline)
        .foregroundColor(.white)
    }
    
//    func loadIsWearDetectionEnabled() {
//            Task {
//                if BleManager.shared.connectedGlasses?.isConnected == true {
//                if let isWearDetectionEnabled = await BleManager.shared.getIsWearDetectionEnabled() {
//                    DispatchQueue.main.async {
//                        wearDetectionEnabled = isWearDetectionEnabled
//                    }
//                }
//            }
//        }
//    }
    
//    private func wearDetectionWidget() -> some View {
//        
//        HStack {
//            HStack(spacing: 8) {
//                Image("glasses_worn")
//                    .renderingMode(.template)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 28, height: 28).foregroundColor(.gray)
//                Text("Wear Detection")
//                    .foregroundColor(.white)
//                    .font(.system(size: 16))
//            }
//            Spacer()
//            Toggle("", isOn: Binding(
//                get: { wearDetectionEnabled ?? false },
//                set: { newVal in
//                    self.wearDetectionEnabled = newVal
//                    Task {
//                        _ = await BleManager.shared.setWearDetectionEnabled(isEnabled: newVal)
//                    }
//                }
//            ))
//            .labelsHidden()
//            .opacity(wearDetectionEnabled == nil ? 0.4 : 1.0)
//            .disabled(wearDetectionEnabled == nil)
//        }
//    }
    
    func unpairGlasses() async {
        guard let connectedGlasses = BleManager.shared.connectedGlasses else { return }
        await BleManager.shared.disconnectFromGlasses(connectedGlasses)
    }
    
    func resetGlasses() async {
        await BleManager.shared.rebootGlasses()
    }
}
