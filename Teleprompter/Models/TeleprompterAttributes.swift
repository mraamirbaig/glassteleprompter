//
//  as.swift
//  Teleprompter
//
//  Created by abaig on 22/08/2025.
//

import ActivityKit
import SwiftUI

struct TeleprompterAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var text: String
        var imageID: String   // reference to cached BMP/PNG
        var isGlassesConnected: Bool
    }

    var scriptTitle: String
}


