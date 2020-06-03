//
//  UIImage+PixelMap.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 1/7/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import Foundation
import Swim

public extension ImageMap {
    init(imagePath path: String, downscaleFactor: Double? = nil) {
        do {
            self.init(try Image<RGB, UInt8>(contentsOf: URL(fileURLWithPath: path)).resized(withFactor: downscaleFactor))
        } catch {
            ColonyPigmentationAnalysisKit.fatalError("Failed to load image at \(path): \(error)")
        }
    }
}

struct InvalidURLPathError: Error { }

public extension PixelMap {
    func save(toPath path: String) throws {
        guard let urlFromString = URL(string: path) else { throw InvalidURLPathError() }
        let url = urlFromString.isFileURL ? urlFromString : URL(fileURLWithPath: path)
        
        try Image(self).write(to: url)
    }
}

// MARK: - Internal

internal extension Image where P == RGB, T == UInt8 {
    init<PM: PixelMap>(_ pixelMap: PM) {
        var flatPixelsArray: [UInt8] = []
        flatPixelsArray.reserveCapacity(pixelMap.size.area * 3)
        
        for y in 0..<pixelMap.size.height {
            for x in 0..<pixelMap.size.width {
                let pixel = pixelMap.pixels[pixelMap.rect.pixelIndex(for: Coordinate(x: x, y: y))]
                flatPixelsArray.append(pixel.color.r)
                flatPixelsArray.append(pixel.color.g)
                flatPixelsArray.append(pixel.color.b)
            }
        }
        
        self.init(width: pixelMap.size.width, height: pixelMap.size.height, data: flatPixelsArray)
    }
}

internal extension ImageMap {
    init(_ image: Image<RGB, UInt8>) {
        var pixels: [RGBColor] = []
        pixels.reserveCapacity(image.width * image.height)

        for x in 0..<image.width {
            for y in 0..<image.height {
                let color: Color<RGB, UInt8> = image[x, y]
                pixels.append(RGBColor(r: color[.red], g: color[.green], b: color[.blue]))
            }
        }

        self.init(height: image.height, pixels: pixels)
    }
}

internal extension Image {
    func resized(withFactor downscaleFactor: Double?) -> Image<P, T> {
        precondition(downscaleFactor.map { $0 > 0 && $0 <= 1 } ?? true, "Downscale factor should be greater than 0 and less than or equal to 1")
        guard let downscaleFactor = downscaleFactor, downscaleFactor < 1 else { return self }
        
        return resize(width: Int(Double(width) * downscaleFactor), height: Int(Double(height) * downscaleFactor))
    }
}
