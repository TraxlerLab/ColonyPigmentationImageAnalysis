//
//  ColonyMeasurements.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 4/19/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import Foundation

// MARK: - Measurements

extension MaskBitMap {
    public func measureColonySize() -> SquarePixels {
        let inMaskPixels = pixels.count(where: { $0 == .white })
        let percentage = Double(inMaskPixels) / Double(pixels.count)
        
        let originalImageSize = size.width * size.height
        return SquarePixels(value: Int((Double(originalImageSize) * percentage).rounded(.down)))
    }
}

public struct SquarePixels {
    public let value: Int
    
    public init(value: Int) {
        self.value = value
    }
    
    public func squareMilimeters(withMicrometersPerPixel micrometersPerPixel: Double) -> SquareMilimeters {
        return SquareMilimeters(value: Double(value) * (micrometersPerPixel * micrometersPerPixel) / (1000 * 1000))
    }
}

public struct SquareMilimeters: Codable {
    public let value: Double
}
