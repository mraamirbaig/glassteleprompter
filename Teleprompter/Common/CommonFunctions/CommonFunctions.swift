////
////  CommonFunctions.swift
////  Teleprompter
////
////  Created by abaig on 17/01/2025.

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class CommonFunctions {
    
    static func getWordCount(text: String) -> Int {
        return text.split { $0.isWhitespace || $0.isNewline }.count
    }
    
    static func endAnyTextFieldEditing() {
        #if os(macOS)
        // Resign first responder in macOS
        NSApp.keyWindow?.makeFirstResponder(nil)
        #else
        // Dismiss the keyboard in iOS
        UIApplication.shared
            .sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        #endif
    }
}
