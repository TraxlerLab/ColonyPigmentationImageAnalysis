//
//  Range+Extensions.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 5/12/20.
//

import Foundation

public extension ClosedRange {
    /// Returns the value clamped to the receiver's bounds.
    /// - Returns: `lowerBound` if `value` is less than `lowerBound`,
    /// `upperBound` if `value` is greater than `upperBound`, and `value`
    /// otherwise.
    func clamping(_ value: Bound) -> Bound {
        return Swift.max(lowerBound, Swift.min(upperBound, value))
    }
}

public protocol _NumericRangeBound {
    var _double: Double { get }
}

extension Double: _NumericRangeBound {
    public var _double: Double { self }
}

extension Int: _NumericRangeBound {
    public var _double: Double { Double(self) }
}

public extension ClosedRange where Bound: _NumericRangeBound {
    /// Returns a value that describes how far from `lowerBound` to `upperBound`
    /// the `value` is.
    /// If `value` is `lowerBound`, the result is `0.0`,
    /// and if `value` is `upperBound`, the result is `1.0`.
    /// If `value` falls outside of the range the return value may be
    /// negative or greater than `1`.
    func interpolation(for value: Bound) -> Double {
        ColonyPigmentationAnalysisKit.assert(upperBound > lowerBound, "Range upper bound \(upperBound) must be greater than lower bound \(lowerBound)")
        
        let doubleLowerBound = lowerBound._double
        let doubleUpperBound = upperBound._double
        
        return (value._double - doubleLowerBound) / (doubleUpperBound - doubleLowerBound)
    }
    
    /// Implements the same functionality as `interpolation(for:)`
    /// but clamping the value between `lowerBound` and `upperBound`.
    func clampedInterpolation(for value: Bound) -> Double {
        return interpolation(for: clamping(value))
    }
}

public extension ClosedRange where Bound == Double {
    /// Returns the value produced by linearly interpolating along the range by
    /// `value`.
    ///
    /// - Parameter value: A value, typically in the range `0...1`, that
    ///   describes how far along the range to interpolate. A value of `0` means
    ///   to return `lowerBound` and a value of `1` means to return
    ///   `upperBound`.
    func interpolating(by value: Double) -> Bound {
        return lowerBound + Bound(value) * (upperBound - lowerBound)
    }
    
    /// Returns a value by linearly interpolating into another range based on a
    /// value evaluated against `self`.
    ///
    /// This method calculates a linear interpolation into `self` using `value`
    /// and then uses that to interpolate into `range`.
    func projecting(_ value: Bound, into range: ClosedRange<Bound>) -> Bound {
        return range.interpolating(by: interpolation(for: value))
    }
}
