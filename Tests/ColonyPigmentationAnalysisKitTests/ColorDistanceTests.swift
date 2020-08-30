//
//  ColorDistanceTests.swift
//  ColonyPigmentationAnalysisKitTests
//
//  Created by Javier Soto on 8/22/20.
//

import Foundation
import XCTest
@testable import ColonyPigmentationAnalysisKit

final class ColorDistanceTests: XCTestCase {
    func testLABColorDistance() {
        func distance(_ color1: ColonyPigmentationAnalysisKit.RGBColor, _ color2: ColonyPigmentationAnalysisKit.RGBColor) -> Double {
            return LABColor(XYZColor(color1)).distance(to: LABColor(XYZColor(color2)))
        }
        
        XCTAssertEqual(distance(.black, .black), 0)
        XCTAssertEqual(distance(.white, .white), 0)
        XCTAssertEqual(distance(.red, .red), 0)
        XCTAssertEqual(distance(.green, .green), 0)
        XCTAssertEqual(distance(.blue, .blue), 0)
        XCTAssertEqual(distance(.white, .black), 1, accuracy: 0.001)
        XCTAssertEqual(distance(.black, .white), 1, accuracy: 0.001)
        XCTAssertEqual(distance(.black, .red), 0.75, accuracy: 0.1)
        XCTAssertEqual(distance(.white, .red), 0.75, accuracy: 0.1)
        XCTAssertEqual(distance(.white, .red), 0.75, accuracy: 0.1)
        XCTAssertEqual(distance(.red, .green), 0.9, accuracy: 0.1)
        XCTAssertEqual(distance(.green, .blue), 1.3, accuracy: 0.1)
        XCTAssertEqual(distance(.red, .blue), 0.86, accuracy: 0.1)
        
        XCTAssertEqual(distance(.testColor1, .testColor2), 0.22, accuracy: 0.1)
    }
    
    func testLABColorNormalizedDistance() {
        func distance(_ color1: ColonyPigmentationAnalysisKit.RGBColor, _ color2: ColonyPigmentationAnalysisKit.RGBColor) -> Double {
            return LABColor(XYZColor(color1)).normalizedDistance(to: LABColor(XYZColor(color2)))
        }
        
        XCTAssertEqual(distance(.black, .black), 0)
        XCTAssertEqual(distance(.white, .white), 0)
        XCTAssertEqual(distance(.red, .red), 0)
        XCTAssertEqual(distance(.green, .green), 0)
        XCTAssertEqual(distance(.blue, .blue), 0)
        XCTAssertEqual(distance(.white, .black), 1, accuracy: 0.001)
        XCTAssertEqual(distance(.black, .white), 1, accuracy: 0.001)
        XCTAssertEqual(distance(.black, .red), 0.75, accuracy: 0.1)
        XCTAssertEqual(distance(.white, .red), 0.75, accuracy: 0.1)
        XCTAssertEqual(distance(.white, .red), 0.75, accuracy: 0.1)
        XCTAssertEqual(distance(.red, .green), 0.9, accuracy: 0.1)
        XCTAssertEqual(distance(.green, .blue), 1, accuracy: 0.1)
        XCTAssertEqual(distance(.red, .blue), 0.86, accuracy: 0.1)
        
        XCTAssertEqual(distance(.testColor1, .testColor2), 0.35, accuracy: 0.1)
    }
}

private extension ColonyPigmentationAnalysisKit.RGBColor {
    static let red = RGBColor(r: 255, g: 0, b: 0)
    static let green = RGBColor(r: 0, g: 255, b: 0)
    static let blue = RGBColor(r: 0, g: 0, b: 255)
    
    // pigmentation
    static let testColor1 = RGBColor(rgbHexString: "803D33")!
    // unpigmented colony color
    static let testColor2 = RGBColor(rgbHexString: "767E7E")!
}
