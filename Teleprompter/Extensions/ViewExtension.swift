//
//  ViewExtension.swift
//  Teleprompter
//
//  Created by abaig on 19/12/2024.
//

import SwiftUI

struct MirroredViewModifier: ViewModifier {
    let isMirrored: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 1, y: isMirrored ? -1 : 1, anchor: .center)
            .clipped()
    }
}


//struct DisableIdleTimer: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .onAppear {
//                UIApplication.shared.isIdleTimerDisabled = true
//            }
//            .onDisappear {
//                UIApplication.shared.isIdleTimerDisabled = false
//            }
//    }
//}

struct DisableIdleTimer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if canImport(UIKit)
                Task { @MainActor in
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                #endif
            }
            .onDisappear {
                #if canImport(UIKit)
                Task { @MainActor in
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                #endif
            }
    }
}

extension View {
    func mirrored(_ isMirrored: Bool) -> some View {
        self.modifier(MirroredViewModifier(isMirrored: isMirrored))
    }
    func disableIdleTimer() -> some View {
        self.modifier(DisableIdleTimer())
    }
}



extension TextAlignment {
    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .leading:
            return .left
        case .center:
            return .center
        case .trailing:
            return .right
        @unknown default:
            return .left
        }
    }
}

extension String {
    func substring(from: Int, to: Int) -> String {
        guard from >= 0, to <= count, from < to else { return "" }
        let start = index(startIndex, offsetBy: from)
        let end = index(startIndex, offsetBy: to)
        return String(self[start..<end])
    }
}
