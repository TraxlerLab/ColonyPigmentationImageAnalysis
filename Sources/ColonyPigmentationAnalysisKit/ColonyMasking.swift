//
//  ColonyMasking.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 1/7/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

public extension ImageMap {
	/// Removes the background from `self` by looking for pixels similar to `backgroundKeyColor`
	/// Parameters:
	/// - backgroundKeyColor: The color to compare the background pixels to.
	/// - colorThreshold: A value between 0 and 1 that represents how sensitive the background removal is.
	///		 			  A higher value means the pixels must be more different from the background to be considered foreground.
	///					  A lower value means colors more different from `backgroundKeyColor` will still be considered background.
    func maskColony(withBackgroundKeyColor backgroundKeyColor: RGBColor, colorThreshold: Double) -> MaskBitMap {
        var result = removeBackground(withBackgroundKeyColor: backgroundKeyColor, colorThreshold: colorThreshold)
        result.removeSmallShapeGroups()
        
        return result
    }

    /// Removes the background from `self` using the provided `mask`.
    func removingBackground(using mask: MaskBitMap) -> ImageMap {
        ColonyPigmentationAnalysisKit.assert(size == mask.size, "Image size (\(size)) must match mask size (\(mask.size))")
        
        var copy = self
        
        copy.unsafeModifyPixels { (pixelIndex, pixel, _) in
            if mask.pixels[pixelIndex] == .black {
                pixel = .black
            }
        }
        
        return copy
    }
}

internal // @testable
extension ImageMap {
    func removeBackground(withBackgroundKeyColor backgroundKeyColor: RGBColor, colorThreshold: Double) -> MaskBitMap {
        precondition((0...1).contains(colorThreshold))
        
        let backgroundLABColor = LABColor(XYZColor(backgroundKeyColor))
        
        var maskBitMap = MaskBitMap(size: size, pixels: [MaskBitMap.Pixel].init(repeating: .black, count: size.area))
        
        maskBitMap.unsafeModifyPixels { (pixelIndex, pixel, pointer) in
            let colorDifference = LABColor(XYZColor(self.pixels[pixelIndex])).normalizedDistance(to: backgroundLABColor, ignoringLightness: false)
            
            if colorDifference > colorThreshold {
                pixel = .white
            }
        }
        
        return maskBitMap
    }
}

internal // @testable
extension MaskBitMap {
    mutating func removeSmallShapeGroups() {
        // Fill in gaps inside the colonies.
        fillInShapesFromInside()
        
        // Remove bubbles that may be big enough to not have been filtered out as noise
        // and which now have been filled out.
        removeGroupsOfAdjacentPixels(smallerThanPercentageOfArea: 0.02)
    }
}

private extension MaskBitMap {
    /// Remove bubbles that may have been big enough to not have been filtered out as noise
    /// and which now have been filled out.
    /// This method assumes that the areas have been filled out first by the masking code.
    mutating func removeGroupsOfAdjacentPixels(smallerThanPercentageOfArea minPercentageOfArea: Double) {
       flipColor(ofGroupsOfColor: .white, ifSmallerThanPercentageOfArea: minPercentageOfArea)
    }
    
    mutating func fillInShapesFromInside() {
       flipColor(ofGroupsOfColor: .black, ifSmallerThanPercentageOfArea: 0.2)
    }

    mutating func flipColor(ofGroupsOfColor groupColor: MaskBitMap.Pixel, ifSmallerThanPercentageOfArea minPercentageOfArea: Double) {
        var seenIndices: Set<Int> = []
        seenIndices.reserveCapacity(pixels.count)
        
        var stack: [Int] = []
        stack.reserveCapacity(pixels.count)
        
        var matchingColorPixelIndicesInGroup: Set<Int> = []
        matchingColorPixelIndicesInGroup.reserveCapacity(pixels.count)
        
        let imageRect = rect
        
        unsafeModifyPixels { (index, pixel, pointer) in
            guard pixel == groupColor && !seenIndices.contains(index) else { return }
            
            stack = [index]
            matchingColorPixelIndicesInGroup = []
            
            while !stack.isEmpty {
                let index = stack.popLast()!
                
                matchingColorPixelIndicesInGroup.insert(index)
                seenIndices.insert(index)
                
                func append(_ coordinate: Coordinate) {
                    let index = imageRect.pixelIndex(for: coordinate)
                    if !seenIndices.contains(index) {
                        stack.append(index)
                        seenIndices.insert(index)
                    }
                }
                
                let coordinate = imageRect.coordinate(forIndex: index)
                
                func appendNeighboringPixelIfWhite(offset: PixelSize) {
                    let neighborPixelCoordinate = coordinate + offset
                    guard imageRect.contains(neighborPixelCoordinate) else { return }
                    
                    let neighborPixelIndex = imageRect.pixelIndex(for: neighborPixelCoordinate)
                    
                    if pointer[neighborPixelIndex] == groupColor {
                        append(neighborPixelCoordinate)
                    }
                }
                
                // Look down first as those are gonna first the next pixels in the array
                // and that's more cache-line-friendly
                appendNeighboringPixelIfWhite(offset: PixelSize(width: 0, height: 1))
                appendNeighboringPixelIfWhite(offset: PixelSize(width: 0, height: -1))
                
                appendNeighboringPixelIfWhite(offset: PixelSize(width: -1, height: -1))
                appendNeighboringPixelIfWhite(offset: PixelSize(width: -1, height: 0))
                appendNeighboringPixelIfWhite(offset: PixelSize(width: -1, height: 1))
                
                appendNeighboringPixelIfWhite(offset: PixelSize(width: 1, height: -1))
                appendNeighboringPixelIfWhite(offset: PixelSize(width: 1, height: 0))
                appendNeighboringPixelIfWhite(offset: PixelSize(width: 1, height: 1))
            }
            
            let minArea = Int(Double(imageRect.size.area) * minPercentageOfArea)
            
            if matchingColorPixelIndicesInGroup.count < minArea {
                for index in matchingColorPixelIndicesInGroup {
                    pointer[index] = groupColor.opposite
                }
            }
        }
    }
}

