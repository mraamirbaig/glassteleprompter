//
//  TeleprompterView.swift
//  Teleprompter
//
//  Created by abaig on 26/02/2025.
//


import SwiftUI

struct TeleprompterView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @StateObject private var controller = TeleprompterActionController()
    
    let onClose: () -> Void
    var loadGlassView: Bool
    @Binding var selectedContent: ContentItem
    
    @State private var showControls = false
    @State private var countdownTimer: Timer?
    @State private var countdownRemaining: Int = 0
    @State private var showCountdown = true
    @State private var isLocked = false
    
    @StateObject private var volumeObserver = VolumeButtonObserver()
    
    var body: some View {
        ZStack {
            if showCountdown {
                Color.black.ignoresSafeArea()
                Text("\(countdownRemaining)")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale)
            } else {
                VStack{
                    if loadGlassView || (!loadGlassView && showControls) {
                            HStack {
                                BottomBarButton(icon: "arrow.uturn.left", action: resetScroll)
                                Spacer()
                                Text(selectedContent.title)
                                    .frame(maxWidth: .infinity,
                                           alignment: .center)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                Spacer()
                                Image(systemName: "eyeglasses")
                                    .foregroundColor(BleManager.shared.connectedGlasses?.isConnected == true ? .green : .red)
                                BottomBarButton(icon: "x.circle", action: {
                                    controller.close()
                                    onClose()
                                })
                            }.padding(.horizontal)
                    }
                    Group{
                        if (loadGlassView == true) {
                            GlassTeleprompterView(controller: controller, selectedContent: $selectedContent)
                        }else {
                            FullScreenTelepropterView(controller: controller, selectedContent: $selectedContent)
                        }
                    }.mirrored(selectedContent.settings.isMirrorEnabled)
                        .onAppear {
                            if selectedContent.settings.selectedMode == .automatic {
                                startAutoScroll()
                            }
                        }
                    Spacer()
                    notchHandle
                            .padding(.bottom, showControls ? 0 : 8)
                    if showControls {
                        bottomBar
                    }
                }.background(Color.black.edgesIgnoringSafeArea(.all))
            }
            
            // Close button visible when showControls is true
            
        }.background(KeyboardHandler(handleUp: handleUpKeyboardKey, handleDown: handleDownKeyboardKey, handleLeft: handleLeftKeyboardKey, handleRight: handleRightKeyboardKey,  handlePlayPause: togglePlayPause))
            .onAppear {
                startCountdown()
                // 1. Start the silent loop once
                    SilentAudioPlayer.shared.start()

                    // 2. Wire callbacks first …
                    volumeObserver.onVolumeUp   = { scrollUp() }
                    volumeObserver.onVolumeDown = { scrollDown() }

                    // 3. … then start the observer
                    volumeObserver.start()
            }
            .onDisappear {
                volumeObserver.stop()
                SilentAudioPlayer.shared.stop()
                stopCountdown()
                if (selectedContent.settings.selectedMode == .automatic) {
                    stopAutoScroll()
                }
            }
            .onTapGesture {
                if !isLocked && !loadGlassView { toggleControls() }
            }
//            .onAppear {
//                if (loadGlassView) {
//                    showControls = true
//                }
//            }
    }
    
    private var notchHandle: some View {
        HStack {
            Spacer()
            Image(systemName: showControls ? "chevron.down" : "chevron.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black)
                .clipShape(Circle())
                .onTapGesture {
                    withAnimation(.spring()) {
                        showControls.toggle()
                    }
                }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func handleUpKeyboardKey() {
        scrollUp()
    }
    
    private func handleDownKeyboardKey() {
        scrollDown()
    }
    
    private func handleLeftKeyboardKey() {
        decreaseFontSpeed()
    }
    
    private func handleRightKeyboardKey() {
        increaseFontSpeed()
    }
    
    private func resetScroll() {
        controller.resetScroll()
    }
    
    private func togglePlayPause() {
        guard selectedContent.settings.selectedMode == .automatic else {
            return
        }
        
        if controller.isScrolling {
            stopAutoScroll()
        } else {
            startAutoScroll()
        }
    }
    
    private func getCurrentFontSizeIndex() -> Int? {
        return SettingsConstants.fontSizes
            .firstIndex(of: selectedContent.settings.fontSize)
    }
    
    private func adjustFontSize(by offset: Int) {
        guard let currentFontSizeIndex = getCurrentFontSizeIndex(),
              let newIndex = getAdjustedFontSizeIndex(from: currentFontSizeIndex, by: offset) else {
            return
        }
        
        selectedContent.settings.fontSize = SettingsConstants
            .fontSizes[newIndex]
        try? selectedContent.modelContext?.save()
    }
    
    private func getAdjustedFontSizeIndex(from currentIndex: Int, by offset: Int) -> Int? {
        let newIndex = currentIndex + offset
        return (0..<SettingsConstants.fontSizes.count).contains(
            newIndex
        ) ? newIndex : nil
    }
    
    private func increaseFontSize() {
        adjustFontSize(by: 1)
    }
    
    private func decreaseFontSize() {
        adjustFontSize(by: -1)
    }
    
    private var bottomBar: some View {
        Group {
            if UIDevice.current.isPad {
                expandedBottomBar
            } else {
                if verticalSizeClass == .compact {
                    expandedBottomBar
                } else {
                    compactBottomBar
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
//        .overlay(Divider().background(Color.white.opacity(0.2)), alignment: .top)
    }
    
    private var compactBottomBar: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                if !loadGlassView {
                    lockControls
                }
                if selectedContent.settings.selectedMode == .automatic {
                    if !loadGlassView {
                        verticalDivider
                    }
                    scrollControls
                }else {
                    if !loadGlassView {
                        verticalDivider
                    }
                    scrollControls
                }
            }

            HStack(spacing: 20) {
                if selectedContent.settings.selectedMode == .automatic {
                    fontSpeedControls
                }
                
                if (!loadGlassView) {
                    fontSizeControls
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    
    private var expandedBottomBar: some View {
        HStack(spacing: 24) {
            if selectedContent.settings.selectedMode == .automatic {
                fontSpeedControls
            } else {
                scrollControls
            }

            if !loadGlassView {
                verticalDivider
                
                lockControls
            }

            if selectedContent.settings.selectedMode == .automatic {
                if loadGlassView {
                    verticalDivider
                }
                scrollControls
            }

            if (!loadGlassView) {
                verticalDivider
                
                fontSizeControls
            }
        }
        .padding()
        .background(Color.black.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var verticalDivider: some View {
        Divider()
            .frame(width: 1, height: 30)
            .background(Color.white.opacity(0.3))
    }


        private var fontSpeedControls: some View {
            HStack {
                BottomBarButton(icon: "minus.circle", action: decreaseFontSpeed)
                BottomBarButton(icon: "speedometer", action: {})
                BottomBarButton(icon: "plus.circle", action: increaseFontSpeed)
            }
        }

        private var lockControls: some View {
            HStack {
                    BottomBarButton(icon: isLocked ? "lock" : "lock.open", action: { isLocked.toggle() })
            }
        }

        private var scrollControls: some View {
            HStack {
                BottomBarButton(icon: "arrow.up.circle", action: scrollUp)

                if (selectedContent.settings.selectedMode == .automatic) {
                    BottomBarButton(icon: controller.isScrolling ? "pause.circle" : "play.circle", action: togglePlayPause)
                }
                
                BottomBarButton(icon: "arrow.down.circle", action: scrollDown)
            }
        }

        private var fontSizeControls: some View {
            HStack {
                    BottomBarButton(icon: "arrow.down.circle", action: decreaseFontSize)
                    BottomBarButton(icon: "textformat.size", action: {})
                    BottomBarButton(icon: "arrow.up.circle", action: increaseFontSize)
            }
        }
    
    private func scrollUp() {
        controller.scrollUp()
    }
    
    private func scrollDown() {
        controller.scrollDown()
    }
    
    private func getCurrentFontSpeedIndex() -> Int? {
        return SettingsConstants.speedPickerValues
            .firstIndex(of: selectedContent.settings.selectedSpeed)
    }
    
    private func adjustFontSpeed(by offset: Int) {
        guard  let currentFontSpeedIndex = getCurrentFontSpeedIndex(),
               let newIndex = getAdjustedFontSpeedIndex(from: currentFontSpeedIndex, by: offset), selectedContent.settings.selectedMode == .automatic else {
            return
        }
        
        selectedContent.settings.selectedSpeed = SettingsConstants
            .speedPickerValues[newIndex]
        try? selectedContent.modelContext?.save()
        
        if (selectedContent.settings.selectedMode == .automatic) {
            controller.updateScrollSpeed() // Restart scrolling with updated speed
        }
    }
    
    private func getAdjustedFontSpeedIndex(from currentIndex: Int, by offset: Int) -> Int? {
        let newIndex = currentIndex + offset
        return (0..<SettingsConstants.speedPickerValues.count).contains(
            newIndex
        ) ? newIndex : nil
    }
    
    private func increaseFontSpeed() {
        withAnimation(.easeInOut(duration: 0.2)) {
            adjustFontSpeed(by: 1)
        }
    }
    
    private func decreaseFontSpeed() {
        withAnimation(.easeInOut(duration: 0.2)) {
            adjustFontSpeed(by: -1)
        }
    }
    
    
    private func startCountdown() {
        countdownRemaining = selectedContent.settings.selectedCountdown
        if countdownRemaining == 0 {
            showCountdown = false
            return
        }
        showCountdown = true
        
        // Show a "Get Ready" screen once at start
//        if loadGlassView {
//            if let readyData = BMPGenerator.create1BitBMPData(text: "Get Ready", alignment: .center, font: selectedContent.settings.selectedFont, size: GlobalConstants.GLASS_FRAME_SIZE) {
//                Task {
//                    await BleManager.shared.sendBmpData(bmpData: readyData)
//                }
//            }
//        }
        
        countdownTimer = Timer
            .scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if countdownRemaining > 0 {
                    countdownRemaining -= 1
                    //                    if (loadGlassView == true) {
                    //                    if let countDownData = BMPGenerator.create1BitBMPData(text: "\(countdownRemaining)", alignment: .center, font: selectedContent.settings.selectedFont, size: GlobalConstants.GLASS_FRAME_SIZE) {
                    //                        FlutterChannelHandler.shared.showBmpImageData(bmpData: countDownData)
                    //                    }
                    //                }
                    
                } else {
                    timer.invalidate()
                    showCountdown = false
                    if (loadGlassView == true) {
                        Task {
                            await BleManager.shared.clearGlasses()
                        }
                    }
                }
            }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func toggleControls() {
        withAnimation { showControls.toggle() }
    }
    
    private func startAutoScroll() {
        
        controller.startScroll()
    }
    
    
    private func stopAutoScroll() {
        
        controller.stopScroll()
    }
}

struct BottomBarButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
        }
    }
}
