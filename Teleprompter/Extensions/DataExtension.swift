//
//  DataExtension.swift
//  Teleprompter
//
//  Created by abaig on 23/05/2025.
//

import UIKit

extension Data {
    func toUInt16LE(at offset: Int) -> UInt16? {
            guard offset + 2 <= count else { return nil }
            return UInt16(littleEndian: self.subdata(in: offset..<offset+2).withUnsafeBytes {
                $0.load(as: UInt16.self)
            })
        }

        func toUInt32LE(at offset: Int) -> UInt32? {
            guard offset + 4 <= count else { return nil }
            return UInt32(littleEndian: self.subdata(in: offset..<offset+4).withUnsafeBytes {
                $0.load(as: UInt32.self)
            })
        }

    func toUIImageFrom1BitGreenOnBlackBMP() -> UIImage? {
            guard self.count > 62 else { return nil } // Ensure header and palette exist

            // Check BMP signature "BM"
            guard self[0] == 0x42, self[1] == 0x4D else { return nil }

            // Read width and height from BMP DIB header
            let width = Int(Int32(littleEndian: self.subdata(in: 18..<22).withUnsafeBytes { $0.load(as: Int32.self) }))
            let height = Int(Int32(littleEndian: self.subdata(in: 22..<26).withUnsafeBytes { $0.load(as: Int32.self) }))
            let bitsPerPixel = Int(UInt16(littleEndian: self.subdata(in: 28..<30).withUnsafeBytes { $0.load(as: UInt16.self) }))
            let pixelOffset = Int(UInt32(littleEndian: self.subdata(in: 10..<14).withUnsafeBytes { $0.load(as: UInt32.self) }))

            guard bitsPerPixel == 1, width > 0, height > 0 else { return nil }

            let rowSize = ((width + 31) / 32) * 4
            let pixelBytes = self[pixelOffset..<(pixelOffset + rowSize * height)]

            var rgbaPixels = [UInt8](repeating: 0, count: width * height * 4)

            for y in 0..<height {
                let rowStart = (height - 1 - y) * rowSize
                for x in 0..<width {
                    let byteIndex = rowStart + (x / 8)
                    let bitIndex = 7 - (x % 8)
                    let byte = pixelBytes[pixelBytes.index(pixelBytes.startIndex, offsetBy: byteIndex)]
                    let bit = (byte >> bitIndex) & 0x1

                    let pixelIndex = (y * width + x) * 4
                    if bit == 0 {
                        // Foreground: Green
                        rgbaPixels[pixelIndex]     = 0   // R
                        rgbaPixels[pixelIndex + 1] = 255 // G
                        rgbaPixels[pixelIndex + 2] = 0   // B
                        rgbaPixels[pixelIndex + 3] = 255 // A
                    } else {
                        // Background: Black
                        rgbaPixels[pixelIndex]     = 0
                        rgbaPixels[pixelIndex + 1] = 0
                        rgbaPixels[pixelIndex + 2] = 0
                        rgbaPixels[pixelIndex + 3] = 255
                    }
                }
            }

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let provider = CGDataProvider(data: NSData(bytes: &rgbaPixels, length: rgbaPixels.count)) else { return nil }

            guard let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            ) else { return nil }

            return UIImage(cgImage: cgImage)
        }

}
