//
//  GlassSerialNumber.swift
//  Teleprompter
//
//  Created by abaig on 15/07/2025.
//
struct GlassSerialNumber {
    let frameCode: String
    let colorCode: String
    let id: String

    init?(from asciiData: Data) {
        // Decode ASCII string from data
        guard let raw = String(data: asciiData, encoding: .ascii) else {
            return nil
        }

        // Define regex pattern
        let pattern = "S\\d{3}L[A-Z]{2}[A-Z]\\d{6}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        // Search for first match in the decoded string
        let range = NSRange(raw.startIndex..., in: raw)
        guard let match = regex.firstMatch(in: raw, range: range),
              let matchRange = Range(match.range, in: raw) else {
            return nil
        }

        // Extract the matched serial number string
        let serial = String(raw[matchRange])

        // Parse components
        self.frameCode = String(serial.prefix(4))                       // SXXX
        self.colorCode = String(serial.dropFirst(4).prefix(3))         // LXX
        self.id = String(serial.dropFirst(7))                           // LXXXXXX
    }


    var fullSerial: String {
        return "\(frameCode)\(colorCode)\(id)"
    }
}

