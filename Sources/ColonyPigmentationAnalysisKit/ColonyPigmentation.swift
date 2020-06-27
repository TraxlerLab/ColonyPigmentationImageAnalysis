//
//  ColonyPigmentation.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 4/19/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import Foundation

// MARK: - Pigmentation

/// A pigmentation value that can be plotted on a 2D graph, representing the average amount of pigmentation across the X axis of the colony.
public struct PigmentationSample {
    /// A value between 0 and 1 that indicates how far along the x axis this sample should be placed in a 2D chart.
    public let x: Double
    
    /// The pigmentation value at this column. A value between 0 and 1.
    public let averagePigmentation: Double
    
    /// The standard deviation from averaging the values at this column.
    public let standardDeviation: Double
    
    /// The indices of the columns averaged in this sample
    public let includedColumnIndices: [Int]
    
    public init(x: Double, averagePigmentation: Double, standardDeviation: Double, includedColumnIndices: [Int]) {
        self.x = x
        self.averagePigmentation = averagePigmentation
        self.standardDeviation = standardDeviation
        self.includedColumnIndices = includedColumnIndices
    }
    
    /// The result of averaging the values in each column of the provided `pigmentationSamples`.
    /// - Warning: All the arrays in `pigmentationSamples` must be the same size.
    public static func averaging(_ pigmentationSamples: [[PigmentationSample]]) -> [PigmentationSample] {
        var averagePigmentations: [PigmentationSample] = []
        
        guard let first = pigmentationSamples.first else {
            preconditionFailure("No pigmentation samples to average")
        }
        
        for (sampleIndex, sample) in first.enumerated() {
            let pigmentationValues = pigmentationSamples.map { $0[sampleIndex].averagePigmentation }
            
            averagePigmentations.append(
                PigmentationSample(
                    x: sample.x,
                    averagePigmentation: pigmentationValues.average,
                    standardDeviation: pigmentationValues.standardDeviation,
                    includedColumnIndices: sample.includedColumnIndices)
            )
        }
        
        return averagePigmentations
    }
}

public extension ImageMap {
    /// Calculates a series of pigmentation values corresponding to the average pigmentation in each column, left to right.
    /// - Parameters
    ///     - colonyMask: A mask (retrived with `colonyMaskingViaChromaKey`) that indicates which pixels of `self` belong to the colony.
    ///     - keyColor: the color to compare all pixels to (considered maximum pigmentation)
    ///     - baselinePigmentation: a cut-off value between 0 and 1 that would cause all pigmentation values below this to be considered not pigmented.
    ///         Values above it would then be interpolated between that value and 1.
    ///     - areaOfInterestHeightPercentage: A value between 0 and 1 to use to only consider pixels at a given x location that are inside a rectangle of height
    ///                               determined by the height of the mask times this value. This can be used to only consider pigmentation across a
    ///                               central "band" in the colony, instead of every pixel.
    ///     - horizontalSamples: An optional value to limit the numher of horizontal samples this will output.
    ///                          (Must be less than the horizontal number of pixel columns in the colony)
    /// - Returns: An array of `PigmentationSample`s.
    func calculate2DPigmentationAverages(withColonyMask colonyMask: MaskBitMap, keyColor: RGBColor,
                                         baselinePigmentation: Double = 0, areaOfInterestHeightPercentage: Double,
                                         horizontalSamples: Int?) -> [PigmentationSample] {
        precondition(size == colonyMask.size, "The colony image and its mask should be the same size \(size) vs \(colonyMask.size)")
        precondition(areaOfInterestHeightPercentage.isNormalized, "areaOfInterestHeightPercentage should be a value between 0 and 1, got \(areaOfInterestHeightPercentage)")
        
        let areaOfInterest = colonyMask.areaOfInterestToCalculatePigmentationOfColonyImage(withHeightPercentage: areaOfInterestHeightPercentage)
        
        var colonyMask = colonyMask
        colonyMask.removePixels(outside: areaOfInterest)

        let expectedNumberOfSamples = horizontalSamples ?? areaOfInterest.size.width
        precondition(areaOfInterest.size.width >= expectedNumberOfSamples, "The specified number of horizontal samples (\(expectedNumberOfSamples) is less than the width of the colony mask (\(areaOfInterest.size.width))")
        
        var samples: [(average: Double, stddev: Double, columnIndices: [Int])] = []
        samples.reserveCapacity(expectedNumberOfSamples)
        
        let maskColumnRange = Double(areaOfInterest.minX)...Double(areaOfInterest.maxX)
        let sampleIndexRange = 0..<expectedNumberOfSamples
        
        let progressPerSample = 1 / Double(expectedNumberOfSamples)
        
        for sampleIndex in sampleIndexRange {
            let progress = progressPerSample * Double(sampleIndex)
            let nextProgress = progress + progressPerSample

            let firstColumn = Int(maskColumnRange.interpolating(by: progress))
            let lastColumn = Int(maskColumnRange.interpolating(by: nextProgress))
            
            let columns = firstColumn..<lastColumn

            var sampledColumnPixels: [RGBColor] = []
            for x in columns {
                for y in areaOfInterest.minY..<areaOfInterest.maxY {
                    let coordinate = Coordinate(x: x, y: y)
                    guard colonyMask[coordinate] == .white else { continue }
                    
                    sampledColumnPixels.append(self[coordinate])
                }
            }
            
            if sampledColumnPixels.isEmpty {
                logger.warning("Found no white pixels in mask for sample index \(sampleIndex) (columns \(columns) in roi \(areaOfInterest)). This may be an error.")
            }
            
            let pigmentationValues = sampledColumnPixels.map({ $0.pigmentation(withKeyColor: keyColor, baselinePigmentation: baselinePigmentation) })
            
            samples.append((average: pigmentationValues.average, stddev: pigmentationValues.standardDeviation, columnIndices: Array(columns)))
        }
        
        precondition(samples.count == expectedNumberOfSamples, "The number of calculated samples (\(samples) doesn't match the expected number of samples (\(expectedNumberOfSamples))")
        
        let pigmentationValuesRange = ClosedRange(samples.indices)
        return samples.enumerated().map {
            PigmentationSample(
                x: pigmentationValuesRange.interpolation(for: $0),
                averagePigmentation: $1.average,
                standardDeviation: $1.stddev,
                includedColumnIndices: $1.columnIndices
            )
        }
    }
    
    /// Calculates a series of pigmentation values corresponding to the average pigmentation in each column, left to right.
    /// Unlike `calculate2DPigmentationAverages`, this version limits the output to `horizontalSamples` samples by interpolating the results,
    /// and instead of returning the values of the pigmentation, returns the x coordinates (from 0 to 1) of each column, repeated a number of times proportional to the pigmentation.
    func calculate1DPigmentationHistogram(withColonyMask colonyMask: MaskBitMap, pigmentationKeyColor: RGBColor,
        interpolateToNumberOfHorizontalSamples horizontalSamples: Int, baselinePigmentation: Double = 0,
        areaOfInterestHeightPercentage: Double) -> [Double] {
        return calculate2DPigmentationAverages(
            withColonyMask: colonyMask, keyColor: pigmentationKeyColor,
            baselinePigmentation: baselinePigmentation, areaOfInterestHeightPercentage: areaOfInterestHeightPercentage,
            horizontalSamples: horizontalSamples
        ).flatMap { (pigmentationSample) -> [Double] in
            let numberOfTimes = Int(pigmentationSample.averagePigmentation / 0.1)
            
            return Array(repeating: pigmentationSample.x, count: numberOfTimes)
        }
    }
}

private extension MaskBitMap {
    func areaOfInterestToCalculatePigmentationOfColonyImage(withHeightPercentage areaOfInterestHeightPercentage: Double) -> Rect {
        var maskCopy = self
        // Figure out the bounding rect of the colony
        guard let maskBoundingRect = maskCopy.colonyBoundingRect() else { ColonyPigmentationAnalysisKit.fatalError("No white pixels found in mask") }
        
        let centerY = maskBoundingRect.midY
        let columnHeight = Int(areaOfInterestHeightPercentage * Double(maskBoundingRect.size.height))
        
        // Remove all the pixels outside the area of interest
        let areaOfInterest = Rect(origin: .init(x: maskBoundingRect.minX, y: centerY - (columnHeight / 2)), size: .init(width: maskBoundingRect.size.width, height: columnHeight))
        maskCopy.removePixels(outside: areaOfInterest)
        
        // Calculate the bounding box again, as removing pixels above and below the rectangle can mean that the leading and trialing edges may have changed
        guard let newMaskBoundingRect = maskCopy.colonyBoundingRect() else { ColonyPigmentationAnalysisKit.fatalError("Couldn't find bounding rect after calculating area of interest" )}
        
        return newMaskBoundingRect
    }
}

private extension RGBColor {
    /// A value from 0 to 1 representing how "pigmented" `self` is based on the provided `keyColor`.
    /// - Parameters
    ///     - keyColor: the color to compare all pixels to (considered maximum pigmentation)
    ///     - baselinePigmentation: a cut-off value between 0 and 1 that would cause all pigmentation values below this to be considered not pigmented.
    ///         Values above it would then be interpolated between that value and 1.`
    func pigmentation(withKeyColor keyColor: RGBColor, baselinePigmentation: Double = 0) -> Double {
        let value = 1 - LABColor(XYZColor(keyColor)).normalizedDistance(to: LABColor(XYZColor(self)), ignoringLightness: false)
        
        return (baselinePigmentation...1).clampedInterpolation(for: value)
    }
}

public extension ImageMap {
    func replacingColonyPixels(withMask mask: MaskBitMap, withPigmentationBasedOnKeyColor keyColor: RGBColor, baselinePigmentation: Double = 0) -> ImageMap {
        ColonyPigmentationAnalysisKit.assert(size == mask.size, "Image size \(size) must match mask size \(mask.size)")
        
        var copy = self
        
        copy.unsafeModifyPixels { (pixelIndex, pixel, pointer) in
            switch mask.pixels[pixelIndex] {
            case .white:
                let pigmentation = pixel.pigmentation(withKeyColor: keyColor, baselinePigmentation: baselinePigmentation)
                
                let gray = UInt8(max(0, min(1, pigmentation)) * 255)
                pixel = RGBColor(r: gray, g: gray, b: gray)
            case .black:
                pixel = .black
            }
        }
        
        return copy
    }
}

private extension MaskBitMap {
    /// Finds the rect in which the colony is perfectly contained within `self`.
    /// Returns nil if no white pixels are found.
    func colonyBoundingRect() -> Rect? {
        let size = self.size
        
        return pixels.withUnsafeBufferPointer { pointer in
            var minX: Int?
            var minY: Int?
            var maxX: Int?
            var maxY: Int?
            
            for x in 0..<size.width {
                for y in 0..<size.height {
                    let coordinate = Coordinate(x: x, y: y)
                    let pixel = pointer[rect.pixelIndex(for: coordinate)]
                    
                    guard pixel == .white else { continue }
                    
                    minX = min(x, minX ?? Int.max)
                    maxX = max(x, maxX ?? 0)
                    
                    minY = min(y, minY ?? Int.max)
                    maxY = max(y, maxY ?? 0)
                }
            }
            
            guard let _minX = minX,
                let _minY = minY,
                let _maxX = maxX,
                let _maxY = maxY
                else { return nil }
            
            let rect = Rect(origin: .init(x: _minX, y: _minY), size: .init(width: _maxX - _minX + 1, height: _maxY - _minY + 1))
            precondition(rect.size.width > 1 && rect.size.height > 1, "Colony size should be larger than 1x1, this is likely an error (size=\(rect.size))")
            
            return rect
        }
    }
}
