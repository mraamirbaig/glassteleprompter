//
//  DeviceExtension.swift
//  Teleprompter
//
//  Created by abaig on 28/05/2025.
//

import UIKit

extension UIDevice {
    var isPad: Bool {
        return userInterfaceIdiom == .pad
    }

    var isLandscape: Bool {
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }
}
