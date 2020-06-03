//
//  Colors.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 2/26/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import Foundation

import Swim

public struct RGBColor: Pixel, Equatable {
    // Note: colors are stored in RGB order
    public var r, g, b: UInt8
    
    public static let black = RGBColor(r: 0, g: 0, b: 0)
    public static let white = RGBColor(r: 255, g: 255, b: 255)

    @inlinable
    public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    public init?(rgbHexString: String) {
        var hexString = rgbHexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        guard hexString.count == 6 else {
            assertionFailure("`init(rgbHexString:)` expects a 6 digit (RRGGBB) hex string")
            return nil
        }
        
        var hexValue: UInt32 = 0
        Scanner(string: hexString).scanHexInt32(&hexValue)
        
        self.init(
            r: UInt8((hexValue & 0xff0000) >> 16),
            g: UInt8((hexValue & 0x00ff00) >> 8),
            b: UInt8((hexValue & 0x0000ff) >> 0)
        )
    }
    
    public var hexString: String {
        return String(format:"#%02X%02X%02X", r, g, b)
    }
    
    @inlinable
    public var brightness: Double {
        var brightness: Double = 0
        brightness += (Double(r) / 255.0) * 0.3
        brightness += (Double(g) / 255.0) * 0.59
        brightness += (Double(b) / 255.0) * 0.11
        
        return brightness
    }
    
    @inlinable
    public var grayScaleValue: Double {
        func coefficient(for component: UInt8) -> Double {
            return Double(component) / 255
        }
        
        return coefficient(for: r) * 0.2126
            + coefficient(for: g) * 0.7152
            + coefficient(for: b) * 0.0722
    }

    /// A gray-scale version of `self`.
    @inlinable
    public var grayScaleColor: RGBColor {
        let grayScaleValue = UInt8(self.grayScaleValue * 255)
        return RGBColor(r: grayScaleValue, g: grayScaleValue, b: grayScaleValue)
    }
    
    @inlinable
    public var luminance: Double {
        func coefficient(for component: UInt8) -> Double {
            let floatComponent = Double(component) / 255
            return floatComponent <= 0.03928 ? floatComponent / 12.92 : pow((floatComponent + 0.055) / 1.055, 2.4)
        }
        
        return coefficient(for: r) * 0.2126
            + coefficient(for: g) * 0.7152
            + coefficient(for: b) * 0.0722
    }
    
    /// MARK: - Pixel
    
    @inlinable
    public var color: RGBColor {
        return self
    }
    
    // MARK: - Distance
    
    private var normalizedRed: Double {
        return Double(r) / 255.0
    }
    
    private var normalizedGreen: Double {
        return Double(g) / 255.0
    }
    
    private var normalizedBlue: Double {
        return Double(b) / 255.0
    }
    
    internal // testable
    func distance(to color: RGBColor) -> Double {
        return sqrt(
            pow(color.normalizedRed - normalizedRed, 2)
                + pow(color.normalizedGreen - normalizedGreen, 2)
                + pow(color.normalizedBlue - normalizedBlue, 2)
        )
    }
}

// MARK: - XYZ Color Space

/// A color space that describes color as it is recieved by the cones of the human eye.
///
/// Can represent any color in the visible spectrum.
public struct XYZColor: Hashable {
    /// Light signal from red cones of the human eye.
    /// Values range from 0 to .95047.
    public var x: Double
    
    /// Light signal from yellow-green cones of the human eye.
    /// Values range from 0 to 1.
    ///
    /// Corresponds to relative luminance
    public var y: Double
    
    /// Light signal from blue cones of the human eye.
    /// Values range from 0 to 1.089.
    public var z: Double
    
    @inlinable
    public init(_ color: RGBColor) {
        func coefficient(for rgbValue: UInt8) -> Double {
            let floatRGBValue = Double(rgbValue) / 255
            return floatRGBValue > 0.04045 ? pow(((floatRGBValue + 0.055) / 1.055), 2.4) : (floatRGBValue / 12.92)
        }
        
        let redCoefficient = coefficient(for: color.r)
        let greenCoefficient = coefficient(for: color.g)
        let blueCoefficient = coefficient(for: color.b)
        
        x = (redCoefficient * 0.4124) + (greenCoefficient * 0.3576) + (blueCoefficient * 0.1805)
        y = (redCoefficient * 0.2126) + (greenCoefficient * 0.7152) + (blueCoefficient * 0.0722)
        z = (redCoefficient * 0.0193) + (greenCoefficient * 0.1192) + (blueCoefficient * 0.9505)
    }
    
    public func distance(to color: XYZColor) -> Double {
        let distance = sqrt(
            pow(color.x - x, 2)
                + pow(color.y - y, 2)
                + pow(color.z - z, 2)
        )
        
        return distance > 0.4 ? 1 : distance
    }
}

// MARK: - LAB Color Space

public struct LABColor: Hashable {
    /// Represents lightness. 0 is darkest black and 100 is brightest white.
    public var l: Double
    
    /// Represents green-red component. Neutral gray is 0, negative values are green and positive values are red.
    /// Value range will vary depending on original color space, but is generally ±100.
    public var a: Double
    
    /// Represents blue-yellow component. Neutral gray is 0, negative values are blue and positive values are yellow.
    /// Value range will vary depending on original color space, but is generally ±100.
    public var b: Double
    
    @inlinable
    public init(l: Double, a: Double, b: Double) {
        self.l = l
        self.a = a
        self.b = b
    }
    
    /// Converts the `l`, `a`, and `b` components to the `[0, 1]` range.
    @usableFromInline
    var normalizedComponents: (l: Double, a: Double, b: Double) {
        return (
            l: (0...100).clampedInterpolation(for: l),
            a: (-100...100).clampedInterpolation(for: a),
            b: (-100...100).clampedInterpolation(for: b)
        )
    }
    
    /// Conversion formula found [here](https://en.wikipedia.org/wiki/CIELAB_color_space#CIELAB%E2%80%93CIEXYZ_conversions).
    /// Constants use [CIE Standard Illuminant D65](https://en.wikipedia.org/wiki/Illuminant_D65)
    public enum LAB2XYZConstants {
        public static let xTristimulus: Double = 0.95047
        public static let yTristimulus: Double = 1
        public static let zTristimulus: Double = 1.08883
        public static let m: Double = 7.787036
        public static let tSubZero: Double = 0.008856
    }
    
    @inlinable
    public init(_ color: XYZColor) {
        func coefficient(for xyzValue: Double) -> Double {
            return xyzValue > LAB2XYZConstants.tSubZero ? pow(xyzValue, 1/3) : (LAB2XYZConstants.m * xyzValue) + (4 / 29)
        }

        let xCoefficient = coefficient(for: color.x / LAB2XYZConstants.xTristimulus)
        let yCoefficient = coefficient(for: color.y / LAB2XYZConstants.yTristimulus)
        let zCoefficient = coefficient(for: color.z / LAB2XYZConstants.zTristimulus)

        l = min(max((116 * yCoefficient) - 16, 0), 100)
        a = 500 * (xCoefficient - yCoefficient)
        b = 200 * (yCoefficient - zCoefficient)
    }
    
    // Delta-E or CIE76
    // http://colormine.org/delta-e-calculator/cie94
    // Returns a value between 0 (same color), and 1 (as different as it can be)
    @inlinable
    public func distance(to color: LABColor, ignoringLightness: Bool = false) -> Double {
        let selfNormalizedComponents = self.normalizedComponents
        let colorNormalizedComponents = color.normalizedComponents
        
        let distance = sqrt(
            (ignoringLightness ? 0 : pow(colorNormalizedComponents.l - selfNormalizedComponents.l, 2))
            + pow(colorNormalizedComponents.a - selfNormalizedComponents.a, 2)
            + pow(colorNormalizedComponents.b - selfNormalizedComponents.b, 2)
        )
        
        ColonyPigmentationAnalysisKit.assert(distance.isNormalized)
        
        return distance
    }
    
    /// The distance from `self` to `color` such that 1 is the maximum distance that can exist between `self` and another color.
    @inlinable
    public func normalizedDistance(to color: LABColor, ignoringLightness: Bool = false) -> Double {
        // First, calculate the furthest distance from `self` to any other color.
        // That distance is the distance to the center of the sphere, plus the radius,
        // as that point is directly opposite to `self` on the other side of the sphere across the center.
        
        let colorAtCenterOfSphere = LABColor(l: 50, a: 0, b: 0)
        let distanceToCenterOfSphere = distance(to: colorAtCenterOfSphere, ignoringLightness: ignoringLightness)
        let sphereRadius: Double = 0.5
        let maximumDistance = distanceToCenterOfSphere + sphereRadius
        ColonyPigmentationAnalysisKit.assert((0...1.1).contains(maximumDistance))
        
        let distance = self.distance(to: color, ignoringLightness: ignoringLightness)
        
        // Then normalize the value into the `0...maximumDistance` range.
        let normalizedDistance = (0...maximumDistance).clampedInterpolation(for: distance)
        
        return normalizedDistance
    }
}

extension Double {
    /// Whether `self` is a value between 0 and 1.
    @usableFromInline
    var isNormalized: Bool {
        return (0...1).contains(self)
    }
}
