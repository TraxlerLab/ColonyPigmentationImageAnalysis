//
//  ColonyPigmentationAnalysisKitTests.swift
//  ColonyPigmentationAnalysisKitTests
//
//  Created by Javier Soto on 1/15/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import XCTest
import Swim
@testable import ColonyPigmentationAnalysisKit

@available(macOS 10.15, *)
final class ImageConversionTests: XCTestCase {
    func testLoadingImage() {
        _ = ImageMap(imagePath: testImagePath(), downscaleFactor: 1)
    }
    
    func testConvertingToSwimFormatAndBackResultsInSameImage() {
        let originalImage = ImageMap(imagePath: testImagePath(), downscaleFactor: 1)
        
        let converted = Image(originalImage)
        let convertedBack = ImageMap(converted)
        
        XCTAssertEqual(originalImage, convertedBack)
    }
}

final class TypeTests: XCTestCase {
}

final class PixelMapTests: XCTestCase {
    func testPixelIndexForCoordinate() {
        let size = PixelSize(width: 2, height: 3)
        let pixelMap = MaskBitMap(size: size, pixels: Array(repeating: .black, count: size.width * size.height))
        
        XCTAssertEqual(pixelMap.rect.pixelIndex(for: Coordinate(x: 0, y: 0)), 0)
        XCTAssertEqual(pixelMap.rect.pixelIndex(for: Coordinate(x: 0, y: 1)), 1)
        XCTAssertEqual(pixelMap.rect.pixelIndex(for: Coordinate(x: 1, y: 0)), 3)
        XCTAssertEqual(pixelMap.rect.pixelIndex(for: Coordinate(x: 1, y: 1)), 4)
    }
    
    func testCoordinateForIndex() {
        let size = PixelSize(width: 2, height: 3)
        let pixelMap = MaskBitMap(size: size, pixels: Array(repeating: .black, count: size.width * size.height))
        
        XCTAssertEqual(pixelMap.rect.coordinate(forIndex: 0), Coordinate(x: 0, y: 0))
        XCTAssertEqual(pixelMap.rect.coordinate(forIndex: 1), Coordinate(x: 0, y: 1))
        XCTAssertEqual(pixelMap.rect.coordinate(forIndex: 2), Coordinate(x: 0, y: 2))
        XCTAssertEqual(pixelMap.rect.coordinate(forIndex: 3), Coordinate(x: 1, y: 0))
        XCTAssertEqual(pixelMap.rect.coordinate(forIndex: 4), Coordinate(x: 1, y: 1))
        XCTAssertEqual(pixelMap.rect.coordinate(forIndex: 5), Coordinate(x: 1, y: 2))
    }
}

@available(macOS 10.15, *)
final class ColonyMaskingTests: XCTestCase {
    func testRemovingBackgroundWithBlackMaskResultsInBlackImage() {
        let originalImage = ImageMap(imagePath: testImagePath(), downscaleFactor: 1)
        
        let mask = MaskBitMap(size: originalImage.size, pixels: Array(repeating: .black, count: originalImage.pixels.count))
        
        let backgroundRemoved = originalImage.removingBackground(using: mask)
        let expected = ImageMap(size: originalImage.size, pixels: Array(repeating: .black, count: originalImage.pixels.count))
        
        XCTAssertEqual(backgroundRemoved, expected)
    }
    
    func testRemovingBackgroundWithWhiteMaskResultsInOriginalImage() {
        let originalImage = ImageMap(imagePath: testImagePath(), downscaleFactor: 1)
        
        let mask = MaskBitMap(size: originalImage.size, pixels: Array(repeating: .white, count: originalImage.pixels.count))
        
        let backgroundRemoved = originalImage.removingBackground(using: mask)
        
        XCTAssertEqual(backgroundRemoved, originalImage)
    }
}
