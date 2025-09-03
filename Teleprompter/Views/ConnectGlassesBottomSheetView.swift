//
//  ConnectGlassesBottomSheetView.swift
//  Teleprompter
//
//  Created by abaig on 02/07/2025.
//

import SwiftUI

struct ConnectGlassesBottomSheetView: View {
    let dismissAction: () -> Void
    @ObservedObject var bleManager: BleManager = BleManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topBar
                if bleManager.isScanning {
                    scanningView
                }else if bleManager.isConnecting {
                    connectingView
                } else {
                    scanResultsView
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            bleManager.startScan()
            
        }.onChange(of: bleManager.connectedGlasses?.isConnected) { _, newValue in
            if bleManager.connectedGlasses?.isConnected == true {
                DispatchQueue.main.async {
                    dismissAction()
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            if !bleManager.isScanning && !bleManager.isConnecting {
                Button(action: { bleManager.startScan() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
            }
            Button(action: { dismissAction() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
    }
    
    private var connectingView: some View {
        VStack(spacing: 20) {
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
        }
        .frame(maxWidth: .infinity)
    }

    private var scanningView: some View {
        VStack(spacing: 20) {
            Image("box_lid_open")
                .resizable()
                .scaledToFit()
            Text("Put Even G1 into the case and leave the cover open.\nThen bring your phone close to the case.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            HStack(spacing: 8) {
                ProgressView()
                Text("Searching for Even G1...")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var scanResultsView: some View {
        VStack(spacing: 16) {
            Image("glasses_not_worn")
                .resizable()
                .scaledToFit()
            Text("We've found the following Even G1 Glasses:")
                .foregroundColor(.white)

            ForEach(bleManager.pairedGlasses, id: \.serialNumber.fullSerial) { glass in
                let channel = glass.channelNumber
                let serialNumber = glass.serialNumber.fullSerial
                HStack {
                    VStack(alignment: .leading) {
                        Text("SN " + "\(serialNumber)")
                            .foregroundColor(.white)
                        Text(bleManager.isConnecting ? "Connecting..." :
                                (bleManager.connectedGlasses?.channelNumber == channel ? "Connected" : "Available"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    Spacer()
                    if bleManager.isConnecting {
                        ProgressView()
                    } else if bleManager.connectedGlasses?.channelNumber != channel {
                        Button("Connect") {
                            Task {
                                await bleManager.connectToGlasses(glass)
                            }
                        }.foregroundColor(.white)
                            .padding()
                            //.background(Color.black)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
