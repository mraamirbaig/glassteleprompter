////
////  s.swift
////  Teleprompter
////
////  Created by abaig on 18/12/2024.
////
//
//import Foundation
//import SwiftUI
//import SwiftData
//
//struct ContentSettings: Codable {
//    var selectedSpeed: Double = SettingsConstants.speedPickerValues.first ?? 1.0
//    var selectedCountdown: Int = SettingsConstants.countdownPickerValues.first ?? 0
//    var showTimer: Bool = true
//    var isMirrorEnabled: Bool = false
//    private var backgroundColorComponents: [CGFloat] = [0.0, 0.0, 0.0, 1.0]
//    private var textColorComponents: [CGFloat] = [1.0, 1.0, 1.0, 1.0]
//    var selectedMode: Mode = .automatic
//    var fontName: String = UIFont.systemFont(ofSize: SettingsConstants.fontSizes.first ?? 24).fontName
//    var fontSize: CGFloat = SettingsConstants.fontSizes.first ?? 24
//    var selectedFontWeight: TextFontWeight = .regular
//    private var textAlignmentValue: Int = 0
//    
//    var backgroundColor: Color {
//        get {
//            Color(red: backgroundColorComponents[0],
//                  green: backgroundColorComponents[1],
//                  blue: backgroundColorComponents[2],
//                  opacity: backgroundColorComponents[3])
//        }
//        set {
//            let uiColor = UIColor(newValue)
//            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
//            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
//            backgroundColorComponents = [red, green, blue, alpha]
//        }
//    }
//    
//    var textColor: Color {
//        get {
//            Color(red: textColorComponents[0],
//                  green: textColorComponents[1],
//                  blue: textColorComponents[2],
//                  opacity: textColorComponents[3])
//        }
//        set {
//            let uiColor = UIColor(newValue)
//            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
//            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
//            textColorComponents = [red, green, blue, alpha]
//        }
//    }
//    
//    var textAlignment: TextAlignment {
//            get {
//                switch textAlignmentValue {
//                case 0:
//                    return .leading
//                case 1:
//                    return .center
//                case 2:
//                    return .trailing
//                default:
//                    return .leading
//                }
//            }
//            set {
//                switch newValue {
//                case .leading:
//                    textAlignmentValue = 0
//                case .center:
//                    textAlignmentValue = 1
//                case .trailing:
//                    textAlignmentValue = 2
//                }
//            }
//        }
//    
//    var selectedFont: UIFont {
//        UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
//    }
//}
import Foundation
import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
#else
import UIKit
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
#endif

struct ContentSettings: Codable {
    var selectedSpeed: Double = SettingsConstants.speedPickerValues.first ?? 1.0
    var selectedCountdown: Int = SettingsConstants.countdownPickerValues.first ?? 0
    var showTimer: Bool = true
    var isMirrorEnabled: Bool = false
    private var backgroundColorComponents: [CGFloat] = [0.0, 0.0, 0.0, 1.0]
    private var textColorComponents: [CGFloat] = [1.0, 1.0, 1.0, 1.0]
    var selectedMode: Mode = .manual
    var fontName: String = PlatformFont.systemFont(ofSize: SettingsConstants.fontSizes.first ?? 32).fontName
    var fontSize: CGFloat = SettingsConstants.fontSizes.first ?? 32
    var selectedFontWeight: TextFontWeight = .regular
    private var textAlignmentValue: Int = 0
    var topPadding: CGFloat = 0
    var bottomPadding: CGFloat = 0
    var leadingPadding: CGFloat = 0
    var trailingPadding: CGFloat = 0
    
    var backgroundColor: Color {
        get {
            Color(red: backgroundColorComponents[0],
                  green: backgroundColorComponents[1],
                  blue: backgroundColorComponents[2],
                  opacity: backgroundColorComponents[3])
        }
        set {
            let platformColor = PlatformColor(newValue)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            backgroundColorComponents = [red, green, blue, alpha]
        }
    }

    var textColor: Color {
        get {
            Color(red: textColorComponents[0],
                  green: textColorComponents[1],
                  blue: textColorComponents[2],
                  opacity: textColorComponents[3])
        }
        set {
            let platformColor = PlatformColor(newValue)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            textColorComponents = [red, green, blue, alpha]
        }
    }

    var textAlignment: TextAlignment {
        get {
            switch textAlignmentValue {
            case 0:
                return .leading
            case 1:
                return .center
            case 2:
                return .trailing
            default:
                return .leading
            }
        }
        set {
            switch newValue {
            case .leading:
                textAlignmentValue = 0
            case .center:
                textAlignmentValue = 1
            case .trailing:
                textAlignmentValue = 2
            }
        }
    }

    var selectedFont: PlatformFont {
        PlatformFont(name: fontName, size: fontSize) ?? PlatformFont.systemFont(ofSize: fontSize)
    }
}
