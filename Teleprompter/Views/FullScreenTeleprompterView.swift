//
//  FullScreenTelepropterView.swift
//  Teleprompter
//
//  Created by abaig on 25/05/2025.
//

import SwiftUI

struct FullScreenTelepropterView: View  {
    
    @ObservedObject var controller: TeleprompterActionController
    
    @Binding var selectedContent: ContentItem
    //    @State private var isScrolling = false
    
    @State private var currentOffset: CGFloat = 0.0
    @State private var scrollTimer: Timer? = nil
    @State private var scrollViewHeight: CGFloat = 0.0
    @State private var scrollHeight: CGFloat = 0.0
    private var alignmentForText: Alignment {
        switch selectedContentAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        @unknown default: return .leading
        }
    }
    private let movelinesOffset: CGFloat = 100
    
    
    private var selectedContentAlignment: TextAlignment {
        
        selectedContent.settings.textAlignment
    }
    
    private var selectedContentTextColor: Color {
        
        selectedContent.settings.textColor
    }
    
    private var selectedContentBackgroundColor: Color {
        
        selectedContent.settings.backgroundColor
    }
    
    private func stopAutoScroll() {
        
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    private func startAutoScroll() {
        
        stopAutoScroll() // Prevent duplicate timers
        let speed = selectedContent.settings.selectedSpeed
        let interval = 0.01
        
        let scrollSpeed = CGFloat(
            speed * 0.2
        ) // Increased multiplier for faster scrolling
        
        scrollTimer = Timer
            .scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                currentOffset += scrollSpeed
            }
    }
    
    // Function to reset scroll position
    private func resetScroll() {
        
        currentOffset = 0
    }
    
    private func scrollUp() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentOffset = max(currentOffset - movelinesOffset, 0)
        }
    }
    
    private func scrollDown() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentOffset += movelinesOffset
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                if (selectedContent.settings.selectedMode == .automatic) {
                    Spacer().frame(height: scrollViewHeight)
                }
                
                Text(selectedContent.text)
                    .font(Font(selectedContent.settings.selectedFont))
                    .fontWeight(selectedContent.settings.selectedFontWeight == .bold ? .bold : .regular)
                    .multilineTextAlignment(selectedContentAlignment)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: alignmentForText)
                if (selectedContent.settings.selectedMode == .automatic) {
                    Spacer().frame(height: scrollViewHeight)
                }
            }.offset(y: -currentOffset)
                .foregroundColor(selectedContentTextColor)
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.async {
                                scrollHeight = geometry.size.height
                            }
                        }
                        .onChange(of: selectedContent.settings.fontSize) { oldValue, newValue in
                            
                            DispatchQueue.main.async {
                                scrollHeight = geometry.size.height
                            }
                            
                        }
                })
        }.background(selectedContentBackgroundColor)
            .onChange(of: controller.resetScrolling) { _, _ in
                resetScroll()
            }
            .onChange(of: controller.scrollingUp) { _, _ in
                scrollUp()
            }
            .onChange(of: controller.scrollingDown) { _, _ in
                scrollDown()
            }
            .onChange(of: controller.isScrolling) { _, _ in
                startStopScroll()
            }
            .onChange(of: controller.scrollSpeedUpdated) { _, _ in
                startStopScroll()
            }
            .allowsHitTesting(false)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.async {
                                scrollViewHeight = geometry.size.height
                                resetScroll()
                            }
                        }
                }
            )
            .padding(EdgeInsets(top: selectedContent.settings.topPadding,
                                leading: selectedContent.settings.leadingPadding,
                                bottom: selectedContent.settings.bottomPadding,
                                trailing: selectedContent.settings.trailingPadding))
            .transition(.move(edge: .bottom))
    }
    
    func startStopScroll() {
        if (controller.isScrolling == true) {
            startAutoScroll()
        }else {
            stopAutoScroll()
        }
    }
}
