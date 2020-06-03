//
//  Types.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 1/26/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

public protocol Pixel {
    var color: RGBColor { get }
}

/// An abstract collection of pixels
public protocol PixelMap {
    associatedtype Pixel: ColonyPigmentationAnalysisKit.Pixel

    var size: PixelSize { get }
    var pixels: [Pixel] { get set }
    
    init(size: PixelSize, pixels: [Pixel])
}

extension PixelMap {
    @inlinable
    public init(height: Int, pixels: [Pixel]) {
        ColonyPigmentationAnalysisKit.assert(pixels.count.isMultiple(of: height), "Number of pixels (\(pixels.count)) must be a multiple of the height (\(height))")
        
        self.init(size: PixelSize(width: pixels.count / height, height: height), pixels: pixels)
    }
    
    @inlinable
    public var rect: Rect {
        return Rect(origin: .zero, size: size)
    }
    
    @inlinable
    public subscript(coordinate: Coordinate) -> Pixel {
        pixels[rect.pixelIndex(for: coordinate)]
    }
}

// MARK: - Pixel Manipulation For Algorithms

internal extension PixelMap {
    @inlinable
    mutating func unsafeModifyPixels(_ f: (Int, inout Pixel, UnsafeMutableBufferPointer<Pixel>) -> Void) {
        let numberOfPixels = pixels.count
        pixels.withUnsafeMutableBufferPointer { (pointer)  in
            for index in 0..<numberOfPixels {
                f(index, &pointer[index], pointer)
            }
        }
    }
}

// MARK: - Coordinate

public struct Coordinate: Equatable, CustomStringConvertible {
    public var x: Int
    public var y: Int
    
    public static let zero = Coordinate(x: 0, y: 0)
    
    @inlinable
    public static func + (lhs: Coordinate, rhs: PixelSize) -> Coordinate {
        return Coordinate(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    
    @inlinable
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    public var description: String {
        return "(\(x), \(y))"
    }
}

public struct PixelSize: Equatable, CustomStringConvertible {
    public let width: Int
    public let height: Int
    
    public static let zero = PixelSize(width: 0, height: 0)
    
    @inlinable
    public var area: Int { width * height }
    
    public var description: String {
        return "\(width)x\(height)"
    }
    
    @inlinable
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    @inlinable
    public init(rectangleOfLength length: Int) {
        self.init(width: length, height: length)
    }
}

public struct Rect: Equatable, CustomStringConvertible {
    public let origin: Coordinate
    public let size: PixelSize
    
    @inlinable
    public init(origin: Coordinate, size: PixelSize) {
        self.origin = origin
        self.size = size
    }
    
    public static let zero = Rect(origin: .zero, size: .zero)
    
    @inlinable
    public var minX: Int { origin.x }
    
    @inlinable
    public var minY: Int { origin.y }
    
    @inlinable
    public var maxX: Int { origin.x + size.width }
    
    @inlinable
    public var maxY: Int { origin.y + size.height }
    
    @inlinable
    public var midX: Int { origin.x + (size.width / 2) }
    
    @inlinable
    public var midY: Int { origin.y + (size.height / 2) }
    
    @inlinable
    public func contains(_ coordinate: Coordinate) -> Bool {
        return coordinate.x >= minX
            && coordinate.x < maxX
            && coordinate.y >= minY
            && coordinate.y < maxY
    }
    
    @inlinable
    public func contains(_ rect: Rect) -> Bool {
        return contains(rect.origin)
            && contains(rect.origin + rect.size)
    }
    
    
    @inlinable
    public func pixelIndex(for coordinate: Coordinate) -> Int {
        ColonyPigmentationAnalysisKit.assert(contains(coordinate), "Coordinate \(coordinate) is not part of \(self)")
        
        return coordinate.y
            + coordinate.x * size.height
    }
    
    @inlinable
    public func pixelIndices(in rect: Rect) -> [Int] {
        var indices: [Int] = []
        indices.reserveCapacity(rect.size.width * rect.size.height)
        
        for x in rect.minX..<rect.maxX {
            for y in rect.minY..<maxY {
                let coordinate = Coordinate(x: x, y: y)
                
                if contains(coordinate) {
                    indices.append(pixelIndex(for: coordinate))
                }
            }
        }
        
        ColonyPigmentationAnalysisKit.assert(indices.count <= rect.size.width * rect.size.height)
        
        return indices
    }
    
    @inlinable
    func pixelsIndices(inPerimeterOf rect: Rect) -> [Int] {
        var indices: [Int] = []
        indices.reserveCapacity(rect.size.width * 2 + rect.size.height * 2)
        
        for x in (rect.minX - 1)...rect.maxX {
            let topPixel = Coordinate(x: x, y: rect.origin.y - 1)
            let bottomPixel = Coordinate(x: x, y: rect.maxY)
            
            indices.append(pixelIndex(for: topPixel))
            indices.append(pixelIndex(for: bottomPixel))
        }
        
        for y in (rect.minY - 1)...rect.maxY {
            let leftPixel = Coordinate(x: rect.origin.x - 1, y: y)
            let rightPixel = Coordinate(x: rect.maxX, y: y)
            
            indices.append(pixelIndex(for: leftPixel))
            indices.append(pixelIndex(for: rightPixel))
        }
        
        return indices
    }
    
    @inlinable
    public func coordinate(forIndex index: Int) -> Coordinate {
        let coordinate = Coordinate(
            x: index / size.height,
            y: index % size.height
        )
        
        return coordinate
    }
    
    public var description: String {
        return "(\(origin), \(size))"
    }
}
