//
//  MaskBitMap.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 1/26/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

/// An image that's composed solely of white or black pixels.
/// Used to represent a mask.
public struct MaskBitMap: PixelMap {
    /// A pixel in a `MaskBitMap`.
    public enum Pixel: ColonyPigmentationAnalysisKit.Pixel, Equatable {
        /// Represents a pixel that's not part of the mask.
        case black
        /// Represents a pixel that is part of the mask.
        case white
        
        @inlinable
        public var color: RGBColor {
            switch self {
            case .black: return .black
            case .white: return .white
            }
        }

        @inlinable
         var opposite: Pixel {
            switch self {
                case .black: return .white
                case .white: return .black
            }
        }
    }

    public let size: PixelSize
    
    public var pixels: [Pixel] {
        didSet {
            precondition(pixels.count == oldValue.count)
        }
    }
    
    @inlinable
    public init(size: PixelSize, pixels: [Pixel]) {
        self.size = size
        self.pixels = pixels
    }
}

