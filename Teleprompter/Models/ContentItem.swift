//
//  ContentItem.swift
//  Teleprompter
//
//  Created by abaig on 18/12/2024.
//

import Foundation
import SwiftData

// SwiftData Model for Content
@Model
class ContentItem {
    var id = UUID()
    var title: String
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var order: Int
    @Attribute(.externalStorage) var settings: ContentSettings
    
    init(title: String, text: String, createdAt: Date = Date(), updatedAt: Date = Date(), order: Int = 0, settings: ContentSettings? = nil) {
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.settings = settings ?? ContentSettings()
    }
}
