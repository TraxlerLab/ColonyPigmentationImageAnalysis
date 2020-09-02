//
//  ImageMap+Drawing.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 5/30/20.
//

import Foundation

extension ImageMap {
    /// Draws the perimeter around the provided rect with the specified `edgeColor`.
    mutating func drawingPerimeter(around rect: Rect, with edgeColor: RGBColor) {
        let pixelIndices = self.rect.pixelsIndices(inPerimeterOf: rect)
        
        pixels.withUnsafeMutableBufferPointer { pointer in
            for index in pixelIndices {
                pointer[index] = edgeColor
            }
        }
    }
    
    mutating func crop(with rect: Rect) {
        precondition(self.rect.contains(rect), "The provided rect \(rect) is not contained within \(self.rect)")
        
        var image = ImageMap(size: rect.size, pixels: [RGBColor](repeating: .black, count: rect.size.area))
        
        image.unsafeModifyPixels { (index, pixel, _) in
            let roiCoordinate = rect.coordinate(forIndex: index)
            let originalImageCoordinate = Coordinate(
                x: roiCoordinate.x + rect.minX,
                y: roiCoordinate.y + rect.minY
            )
            
            pixel = self[originalImageCoordinate]
        }
        
        self = image
    }
}

extension MaskBitMap {
    /// Masks all the pixels outside of `rect` as `.black`.
    mutating func removePixels(outside rect: Rect) {
        unsafeModifyPixels { [totalRect = self.rect] (index, pixel, pointer) in
            if !rect.contains(totalRect.coordinate(forIndex: index)) {
                pixel = .black
            }
        }
    }
}
