//
//  Mode.swift
//  Teleprompter
//
//  Created by abaig on 18/12/2024.
//

enum Mode: String, CaseIterable, Identifiable, Codable {  // Added Codable
    case automatic = "Automatic"
    case manual = "Manual"
    
    var id: String { self.rawValue }
}
