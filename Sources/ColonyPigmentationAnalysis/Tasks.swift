//
//  Tasks.swift
//  ColonyPigmentationAnalysis
//
//  Created by Javier Soto on 28/5/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import ColonyPigmentationAnalysisKit
import Foundation

// MARK: - Task Definition

protocol StorableInDisk {
    static var fileExtension: String { get }

    func save(toPath path: String) throws
}

struct Task<Input, Configuration, Output: StorableInDisk> {
    let name: String
    fileprivate let process: (Input, Configuration) -> Output

    @discardableResult
    func run(withInput input: Input, configuration: Configuration) throws -> Output {
        return process(input, configuration)
    }
}

struct TaskRunner {
    let inputImageName: String
    let outputDirectory: String
    let detailedProgressOutput: Bool

    @discardableResult
    func run<Input, Configuration, Output>(_ task: Task<Input, Configuration, Output>, withInput input: Input, configuration: Configuration, artifactDirectory: String) throws -> Output {
        func perform() throws -> Output {
            let result = try task.run(withInput: input, configuration: configuration)

            let folderPath = outputDirectory.appendingPathComponent(artifactDirectory)
            try createDirectory(folderPath)

            try result.save(toPath: folderPath.appendingPathComponent("\(inputImageName).\(Output.fileExtension)"))
            
            return result
        }

        if detailedProgressOutput {
            return try measure(name: "\(task.name): \(inputImageName)", perform)
        } else {
            return try perform()
        }
    }
}

enum TaskError: Swift.Error {
    case failedToCreateResultDirectory(path: String, underlyingError: Swift.Error)
}

// MARK: - Load Image

struct LoadImageTaskConfiguration {
    let downscaleFactor: Double
}

let loadImageTask = Task<String, LoadImageTaskConfiguration, ImageMap>(name: "Load image") { imagePath, configuration in
    return ImageMap(
            imagePath: imagePath,
            downscaleFactor: configuration.downscaleFactor
    )
}

// MARK: - Mask Colony

struct MaskColonyTaskConfiguration {
    let backgroundChromaKeyColor: ColonyPigmentationAnalysisKit.RGBColor
    let backgroundChromaKeyThreshold: Double
}

let maskColonyTask = Task<ImageMap, MaskColonyTaskConfiguration, MaskBitMap>(name: "Mask Colony") { image, configuration in
    return image.maskColony(
        withBackgroundKeyColor: configuration.backgroundChromaKeyColor,
        colorThreshold: configuration.backgroundChromaKeyThreshold
    )
}

// MARK: - Remove Background

let removeBackgroundTask = Task<(ImageMap, MaskBitMap), (), ImageMap>(name: "Remove Background") { input, _ in
    return input.0.removingBackground(using: input.1)
}

// MARK: - Pigmentation Histogram

struct PigmentationHistogramTaskConfiguration {
    let pigmentationColor: ColonyPigmentationAnalysisKit.RGBColor
    let baselinePigmentation: Double
    let pigmentationValuesToSubtract: [Double]?
    let pigmentationAreaOfInterestHeightPercentage: Double
    let horizontalSamples: Int?
}

let pigmentationHistogramTask = Task<(ImageMap, MaskBitMap), PigmentationHistogramTaskConfiguration, [PigmentationSample]>(name: "Pigmentation Histogram") { input, configuration in
    return input.0.calculate2DPigmentationAverages(
        withColonyMask: input.1,
        keyColor: configuration.pigmentationColor,
        baselinePigmentation: configuration.baselinePigmentation,
        pigmentationValuesToSubtract: configuration.pigmentationValuesToSubtract,
        areaOfInterestHeightPercentage: configuration.pigmentationAreaOfInterestHeightPercentage,
        horizontalSamples: configuration.horizontalSamples
    )
}

// MARK: - Pigmentation Series

let pigmentationSeriesTask = Task<[PigmentationSample], Void, CSV>(name: "Pigmentation Series") { input, configuration in
    let pigmentationSeries = input.oneDimensionHistogram()

    return CSV(contents: pigmentationSeries.map({ String(format: "%f", $0) }).joined(separator: "\n"))
}

// MARK: - Draw Pigmentation

struct DrawPigmentationTaskConfiguration {
    var pigmentationColor: ColonyPigmentationAnalysisKit.RGBColor
    var baselinePigmentation: Double
    var pigmentationValuesToSubtract: [Double]? = nil
    var areaOfInterestHeightPercentage: Double = 1
}

let drawPigmentationTask = Task<(ImageMap, MaskBitMap), DrawPigmentationTaskConfiguration, ImageMap>(name: "Draw Pigmentation") { input, configuration in
    return input.0.replacingColonyPixels(
            withMask: input.1,
            withPigmentationBasedOnKeyColor: configuration.pigmentationColor,
            baselinePigmentation: configuration.baselinePigmentation,
            pigmentationValuesToSubtract: configuration.pigmentationValuesToSubtract,
            areaOfInterestHeightPercentage: configuration.areaOfInterestHeightPercentage
    )
}
