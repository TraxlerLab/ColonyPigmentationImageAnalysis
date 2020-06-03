//
//  PerformanceTests.swift
//  ColonyPigmentationAnalysisKitTests
//
//  Created by Javier Soto on 4/20/20.
//

import XCTest
@testable import ColonyPigmentationAnalysisKit

@available(macOS 10.15, *)
final class PerformanceTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        #if !os(macOS)
        throw XCTSkip("Skipping performance tests outside macOS / Xcode")
        #endif
    }
    
    func testColorDistancePerformance() {
        measure {
            let color1 = RGBColor.black
            let color2 = RGBColor(r: 51, g: 57, b: 62)
            _ = LABColor(XYZColor(color2)).normalizedDistance(to: LABColor(XYZColor(color1)))
        }
    }
    
    func testImageLoadingPerformance() {
        measure {
            _ = ImageMap(imagePath: testImagePath(), downscaleFactor: 1)
        }
    }
    
    func testImageSavingPerformance() throws {
        let image = ImageMap(imagePath: testImagePath(), downscaleFactor: 1)
        
        measure {
            let tempPath = tempDirectoryURL().appendingPathComponent("temp_image_\(UUID().uuidString).jpg").relativeString
            try! image.save(toPath: tempPath)
        }
    }
    
    func testRemovingBackgroundPerformance() {
        let image = ImageMap(imagePath: testImagePath())
        
        measure {
            _ = image.removeBackground(withBackgroundKeyColor: RGBColor(r: 51, g: 57, b: 62), colorThreshold: 0.15)
        }
    }
    
    func testSmallShapeRemovalPerformance() {
        let image = ImageMap(imagePath: testImagePath(), downscaleFactor: 1)
        let maskWithoutBackground = image.removeBackground(withBackgroundKeyColor: RGBColor(r: 51, g: 57, b: 62), colorThreshold: 0.15)
        
        measure {
            var copy = maskWithoutBackground
            copy.removeSmallShapeGroups()
        }
    }
    
    func testColonyMaskingPerformance() {
        let image = ImageMap(imagePath: testImagePath())
        
        measure {
            _ = image.maskColony(withBackgroundKeyColor: RGBColor(r: 51, g: 57, b: 62), colorThreshold: 0.15)
        }
    }
    
    func testRemoveBackgroundWithMaskPerformance() {
        let image = ImageMap(imagePath: testImagePath())
        let mask = image.maskColony(withBackgroundKeyColor: RGBColor(r: 51, g: 57, b: 62), colorThreshold: 0.15)
        
        measure {
            _ = image.removingBackground(using: mask)
        }
    }

    // MARK: - Private
    
    private func tempDirectoryURL() -> URL {
        return try! FileManager.default.url(for: .cachesDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
    }
}
