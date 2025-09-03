//
//  Settings.swift
//  Teleprompter
//
//  Created by abaig on 18/12/2024.
//

import SwiftUI

struct SettingsConstants {
    
    static let settingsMenuWidth = 310.0
    static let speedPickerValues = Array(stride(from: 5.0, through: 20.0, by: 1.0))
    static let countdownPickerValues = Array(stride(from: 0, through: 9, by: 1))
    static let fontSizes: [CGFloat] = Array(stride(from: 32.0, through: 102.0, by: 2.0))

    static var leadingAndTrailingPaddingRange: ClosedRange<CGFloat> {
        let maxPadding = (getMinDimension - settingsMenuWidth) / 2
        return 0...maxPadding
    }

    static var topAndBottomPaddingRange: ClosedRange<CGFloat> {
        let maxPadding = (getMinDimension - 264) / 2
        return 0...maxPadding
    }

    static private var getMinDimension: CGFloat {
        #if os(iOS)
        return min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        #else
        if let screen = NSScreen.main {
            return min(screen.frame.width, screen.frame.height)
        }
        return 800 // Default fallback for macOS
        #endif
    }
}

