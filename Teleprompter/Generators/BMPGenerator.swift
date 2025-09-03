//
//  ImageHelper.swift
//  Teleprompter
//
//  Created by abaig on 23/05/2025.
//

import UIKit

struct BMPGenerator {
    
    static func create1BitBMPData(text: String, alignment: NSTextAlignment, font: PlatformFont, size: CGSize) -> Data? {
        print("Starting BMP creation for text: '\(text)'")
        
        guard let image = renderTextImage(text: text, alignment: alignment, font: font, size: size),
              let cgImage = image.cgImage else { return nil }

        let width = Int(size.width)
        let height = Int(size.height)
        
        guard let bitmap = generate1BitPixelData(from: cgImage, width: width, height: height) else { return nil }
        
        let bmpData = assembleBMP(with: bitmap, width: width, height: height)
        
        print("✅ BMP created: \(bmpData.count) bytes, Green text on black background")
        return bmpData
    }

    // MARK: - Step 1: Render Text to UIImage
    private static func renderTextImage(text: String, alignment: NSTextAlignment, font: PlatformFont, size: CGSize) -> UIImage? {
        
        let paddingTop: CGFloat = font.ascender
            let paddedSize = CGSize(width: size.width, height: size.height + paddingTop)
        
        UIGraphicsBeginImageContextWithOptions(paddedSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: paddedSize))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.green,
            .paragraphStyle: paragraphStyle,
        ]
        
        let textRect = CGRect(x: 0, y: paddingTop, width: size.width, height: size.height)
        //let textRect = CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 10)
        let attrString = NSAttributedString(string: text, attributes: attributes)
        attrString.draw(in: textRect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Step 2: Convert UIImage to 1-bit bitmap
    private static func generate1BitPixelData(from cgImage: CGImage, width: Int, height: Int) -> Data? {
        guard let provider = cgImage.dataProvider,
              let pixelData = provider.data else { return nil }

        let data = CFDataGetBytePtr(pixelData)!
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        let rowPadded = ((width + 31) / 32) * 4
        var bmpPixels = Data(count: rowPadded * height)

        bmpPixels.withUnsafeMutableBytes { ptr in
            guard let bmpBytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }

            for y in 0..<height {
                var bitBuffer: UInt8 = 0
                var bitCount = 0
                let bmpRowStart = (height - 1 - y) * rowPadded

                for x in 0..<width {
                    let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                    let b = data[pixelIndex]
                    let g = data[pixelIndex + 1]
                    let r = data[pixelIndex + 2]

                    let isFg = (g > 150 && r < 100 && b < 100)
                    let bit = isFg ? 0 : 1

                    bitBuffer = (bitBuffer << 1) | UInt8(bit)
                    bitCount += 1

                    if bitCount == 8 {
                        bmpBytes[bmpRowStart + (x / 8)] = bitBuffer
                        bitBuffer = 0
                        bitCount = 0
                    }
                }

                if bitCount > 0 {
                    bitBuffer <<= (8 - bitCount)
                    bmpBytes[bmpRowStart + (width - 1) / 8] = bitBuffer
                }
            }
        }

        return bmpPixels
    }

    // MARK: - Step 3: Assemble BMP headers and pixel data
    private static func assembleBMP(with pixelData: Data, width: Int, height: Int) -> Data {
        let fileHeaderSize = 14
        let infoHeaderSize = 40
        let paletteSize = 8
        let fileSize = fileHeaderSize + infoHeaderSize + paletteSize + pixelData.count
        let dataOffset = fileHeaderSize + infoHeaderSize + paletteSize

        let paletteBg: [UInt8] = [0, 0, 0, 0]       // Black
        let paletteFg: [UInt8] = [0, 255, 0, 0]     // Green

        var bmpData = Data()
        bmpData.append(contentsOf: [0x42, 0x4D]) // "BM"
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian, Array.init))
        bmpData.append(contentsOf: [0, 0, 0, 0]) // Reserved
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(dataOffset).littleEndian, Array.init))

        // DIB header
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(infoHeaderSize).littleEndian, Array.init))
        bmpData.append(contentsOf: withUnsafeBytes(of: Int32(width).littleEndian, Array.init))
        bmpData.append(contentsOf: withUnsafeBytes(of: Int32(height).littleEndian, Array.init))
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))   // Planes
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))   // BPP
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian, Array.init))   // No compression
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(pixelData.count).littleEndian, Array.init))
        bmpData.append(contentsOf: withUnsafeBytes(of: Int32(2835).littleEndian, Array.init)) // Horz res
        bmpData.append(contentsOf: withUnsafeBytes(of: Int32(2835).littleEndian, Array.init)) // Vert res
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(2).littleEndian, Array.init))   // Colors
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian, Array.init))   // Important colors

        bmpData.append(contentsOf: paletteBg)
        bmpData.append(contentsOf: paletteFg)
        bmpData.append(pixelData)

        return bmpData
    }
}
