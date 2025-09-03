//
//  TextFontWeight.swift
//  Teleprompter
//
//  Created by abaig on 22/01/2025.
//

enum TextFontWeight: String, CaseIterable, Identifiable, Codable {  // Added Codable
    case regular = "Regular"
    case bold = "Bold"
    
    
    var id: String { self.rawValue }
}
