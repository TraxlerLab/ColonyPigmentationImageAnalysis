//
//  ImageMap.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 1/7/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

/// A map of `RGBColor` pixels.
public struct ImageMap: PixelMap, Equatable {
    public let size: PixelSize
    
    public var pixels: [RGBColor] {
        didSet {
            precondition(pixels.count == oldValue.count)
        }
    }
    
    @inlinable
    public init(size: PixelSize, pixels: [RGBColor]) {
        self.size = size
        self.pixels = pixels
    }
}
