//
//  TeleprompterActionController.swift
//  Teleprompter
//
//  Created by abaig on 24/05/2025.
//

class TeleprompterActionController: ObservableObject {
    
    @Published var resetScrolling = false
    @Published var isScrolling = false

    @Published var scrollSpeedUpdated = false
    
    @Published var scrollingUp = false
    @Published var scrollingDown = false
    
    @Published var isClosing = false
    
    func resetScroll() {
        resetScrolling.toggle()
    }
    
    func startScroll() {
        isScrolling = true
    }
    
    func stopScroll() {
        isScrolling = false
    }
    
    func updateScrollSpeed() {
        scrollSpeedUpdated.toggle()
    }
    
    func scrollUp() {
        scrollingUp.toggle()
    }


    func scrollDown() {
        scrollingDown.toggle()
    }
    
    func close() {
        isClosing.toggle()
    }
}
