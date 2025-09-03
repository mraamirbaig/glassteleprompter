//
//  GlassTextListView.swift
//  Teleprompter
//
//  Created by abaig on 23/05/2025.
//

import SwiftUI
import UserNotifications

struct GlassTeleprompterView: View {
    
    @ObservedObject var controller: TeleprompterActionController
    
    @Binding var selectedContent: ContentItem
    
    @State private var bmpDataList: [Data] = []
    @State private var hasSavedFiles = false
    
    @State private var isLoading = true // global loading state
    @State private var uiImageCache: [UIImage?] = [] // cache for decoded images
//    @State private var cellLoadingStates: Set<Int> = []  // track loading cells by index
    @State private var selectedIndex: Int? = nil
    
    @State private var scrollTimer: Timer? = nil
    
//    @State private var showScrollEndAlert = false
    @State private var isSendingBMPData: Bool = false
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.6))
                .ignoresSafeArea()
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(uiImageCache.indices, id: \.self) { index in
                                if let image = uiImageCache[index] {
                                    ZStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.black)
                                            .padding()
                                            
                                        if selectedIndex != index {
                                                    Color.white.opacity(0.2)
                                                        .edgesIgnoringSafeArea(.all)
                                                }
                                    }.onTapGesture {
                                        
                                        sendBmpDataAtIndex(index: index)
                                        withAnimation {
                                            scrollProxy.scrollTo(index, anchor: .top)
                                        }
                                    }
                                }else {
                                            VStack {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                    .scaleEffect(1.2)
                                                    .padding()
                                                Text("Loading frame ...")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(maxWidth: .infinity, minHeight: 100)
                                            .background(Color.black)
//                                            .border(Color.green, width: 1)
                                        }
                            }
                        }
//                        .padding()
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        if let index = newIndex {
                            withAnimation {
                                scrollProxy.scrollTo(index, anchor: .top)
                            }
                            
                        }
                    }
                }
            }
            if isSendingBMPData {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Sending text to glasses…")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isSendingBMPData)
                }
        }
        
//        .alert(isPresented: $showScrollEndAlert) {
//            Alert(
//                title: Text("Teleprompter Ended"),
//                message: Text("Please choose the teleprompter mode you want to use."),
//                primaryButton: .default(Text("Restart")) {
//                    resetScroll()
//                    startAutoScroll()
//                },
//                secondaryButton: .cancel(Text("Cancel")) {
//        
//                }
//            )
//        }
        .onAppear {
            guard !hasSavedFiles else { return }
            isLoading = true
            DispatchQueue.global(qos: .userInitiated).async {
                let pages = generateBMPPages(
                    text: selectedContent.text,
                    font: selectedContent.settings.selectedFont,
                    alignment: selectedContent.settings.textAlignment.nsTextAlignment,
                    size: GlobalConstants.GLASS_FRAME_SIZE
                )
                
                    self.bmpDataList = pages
                    if !self.bmpDataList.isEmpty {
                        self.uiImageCache = self.bmpDataList.map { data in
                                    return data.toUIImageFrom1BitGreenOnBlackBMP()
                                }
                        DispatchQueue.main.async {
                            sendBmpDataAtIndex(index: 0)
                        }
                    }
                    self.hasSavedFiles = true
                    self.isLoading = false
            }
            
        }
        .onDisappear {
            scrollTimer?.invalidate()
//            Task {
//                try await BleManager.shared.removeBmpImage()
//            }
        }
        .onChange(of: controller.scrollingUp) { _, _ in
            scrollUp()
        }
        .onChange(of: controller.scrollingDown) { _, _ in
            scrollDown()
        }
        .onChange(of: controller.resetScrolling) { _, _ in
            resetScroll()
        }
        .onChange(of: controller.isScrolling) { _, _ in
            startStopScroll()
        }
        .onChange(of: controller.scrollSpeedUpdated) { _, _ in
            startStopScroll()
        }.onChange(of: controller.isClosing) { _, _ in
            Task {
                await clearGlasses()
            }
        }
        .onChange(of: BleManager.shared.connectedGlasses?.isConnected) { _, newValue in
//            if newValue == true {
//                print("Connected again after disconnect")
//                Task {
////                    isSendingBMPData = true
////                    await clearGlasses()
//                    try? await Task.sleep(nanoseconds: 2_000_000_000)
//                    retrySendingBMPData()
//                }
//            }else {
//                
//            }
            if let index = selectedIndex, let image = uiImageCache[index] {
                    sendImageToTeleprompterWidget(image: image)
            }
        }
    }
    
    func retrySendingBMPData() {
        
        isSendingBMPData = false
        if let index = selectedIndex {
            sendBmpDataAtIndex(index: index)
        }
    }
    
    func clearGlasses() async {
        
        let success = await BleManager.shared.clearGlasses()
            if success {

                    TeleprompterWidgetManager.shared.end()
                }
    }
    
//    private func sendBmpDataAtIndex(index: Int) {
//        
//        guard !isSendingBMPData else { return } // prevent double triggers
//            isSendingBMPData = true
//            
//            Task {
//                let success = await BleManager.shared.sendBmpData(bmpDataList[index])
//                
//                await MainActor.run {
//                    if success {
//                        selectedIndex = index
//                    }
//                    isSendingBMPData = false
//                }
//            }
//    }

    private func sendBmpDataAtIndex(index: Int) {
        guard !isSendingBMPData && BleManager.shared.connectedGlasses?.isConnected == true else { return }
        isSendingBMPData = true
        
        
        BleManager.shared.sendBmpData(bmpDataList[index]) { success in
            DispatchQueue.main.async {
                isSendingBMPData = false
                if success {
                    selectedIndex = index
                    if let image = uiImageCache[index] {
                        sendImageToTeleprompterWidget(image: image)
                        //TeleprompterWidgetManager.shared.show(image: image, text: selectedContent.title, isGlassesConnected: BleManager.shared.connectedGlasses?.isConnected ?? false)
                    }
                    
                }else {
                    sendBmpDataAtIndex(index: index)
                }
            }
        }
    }
    
    private func sendImageToTeleprompterWidget(image: UIImage) {
        
        TeleprompterWidgetManager.shared.show(image: image, text: selectedContent.title, isGlassesConnected: BleManager.shared.connectedGlasses?.isConnected ?? false)
    }
    
//    private func sendBmpDataAtIndex(index: Int, retryCount: Int = 0, maxRetries: Int = 5) {
//        guard !isSendingBMPData else { return }
//        isSendingBMPData = true
//        
//        BleManager.shared.sendBmpData(bmpDataList[index]) { success in
//            DispatchQueue.main.async {
//                self.isSendingBMPData = false
//                
//                if success {
//                    self.selectedIndex = index
//                    if let image = self.uiImageCache[index] {
//                        TeleprompterWidgetManager.shared.show(
//                            image: image,
//                            text: self.selectedContent.title,
//                            isGlassesConnected: BleManager.shared.connectedGlasses != nil
//                        )
//                    }
//                } else if retryCount < maxRetries {
//                    // Retry with delay
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        self.sendBmpDataAtIndex(index: index, retryCount: retryCount + 1, maxRetries: maxRetries)
//                    }
//                } else {
//                    print("❌ Failed to send BMP data after \(maxRetries) retries.")
//                }
//            }
//        }
//    }

    
    private func scrollUp() {
        guard let currentIndex = selectedIndex, currentIndex > 0 else { return }
        let newIndex = currentIndex - 1
        
        sendBmpDataAtIndex(index: newIndex)
    }
    
    private func scrollDown() {
        guard let currentIndex = selectedIndex else { return }

        if currentIndex < bmpDataList.count - 1 {
            let newIndex = currentIndex + 1
            
            sendBmpDataAtIndex(index: newIndex)
        } else if controller.isScrolling {
            // Stop scrolling and trigger alert after delay
//            stopAutoScroll()
//            DispatchQueue.main.asyncAfter(deadline: .now() + selectedContent.settings.selectedSpeed) {
//                showScrollEndAlert = true
//                controller.isScrolling = false
//            }
            resetScroll()
            startAutoScroll()
        }else {
            resetScroll()
        }
    }
    
    func resetScroll() {
        
        sendBmpDataAtIndex(index: 0)
    }
    
    func startStopScroll() {
        if (controller.isScrolling == true) {
            startAutoScroll()
        }else {
            stopAutoScroll()
        }
    }
    
    private func stopAutoScroll() {
        
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    private func startAutoScroll() {
        
        stopAutoScroll() // Prevent duplicate timers
        controller.isScrolling = true
        let interval = selectedContent.settings.selectedSpeed
        
        scrollTimer = Timer
            .scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                scrollDown()
            }
    }
    
    
    func generateBMPPages(text: String, font: UIFont, alignment: NSTextAlignment, size: CGSize) -> [Data] {
        let pages = splitTextIntoPagesAccordingToSize(text: text, font: font,alignment: alignment, size: size)
        return pages.compactMap { pageText in
            return BMPGenerator.create1BitBMPData(text: pageText, alignment: alignment, font: font, size: size)
        }
    }
    
    func splitTextIntoPagesAccordingToSize(text: String, font: UIFont, alignment: NSTextAlignment, size: CGSize) -> [String] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attrString = NSAttributedString(string: text, attributes: [
            .font: font,
            .paragraphStyle: paragraphStyle,
        ])
        
        let textStorage = NSTextStorage(attributedString: attrString)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        var pages: [String] = []
        var glyphIndex = 0
        
        while glyphIndex < layoutManager.numberOfGlyphs {
            let textContainer = NSTextContainer(size: CGSize(width: size.width, height: size.height))
            textContainer.lineFragmentPadding = 0
            textContainer.lineBreakMode = .byWordWrapping
            layoutManager.addTextContainer(textContainer)
            
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            
            let pageText = (textStorage.string as NSString).substring(with: charRange)
            pages.append(pageText)
            
            glyphIndex = NSMaxRange(glyphRange)
        }
        
        return pages
    }
}

