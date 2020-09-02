//
//  ViewController.swift
//  ColonyPigmentationAnalysis
//
//  Created by Javier Soto on 1/5/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import Foundation

import ArgumentParser
import Logging
import ColorizeSwift

import ColonyPigmentationAnalysisKit

// MARK: - Logging

let logger = Logger(label: "ColonyPigmentationAnalysis")

// MARK: - CLI tool

struct Main: ParsableCommand {
    @Option(parsing: .upToNextOption, help: "Paths to the jpg images to analyze. Use a wildcard to pass many images. Example: 'images/*.jpg'")
    var images: [String]

    @Option(default: "output/", help: "Path to a directory where the results will be saved")
    var outputPath: String

    @Flag(name: .long, default: false, inversion: .prefixedNo, help: "Whether to print step by step information of the progress")
    var detailedProgress: Bool
    
    @Option(default: 1, help: "A value between 0 and 1 that will be multiplied by the width and height of each image to downscale them before processing.\nUse this if processing the images is too slow on your machine, although it will produce less precise results.")
    var downscaleFactor: Double
    
    @Option(default: .init(r: 51, g: 57, b: 62), help: "An RGB color to compare pixels against to separate colonies from the background")
    var backgroundChromaKeyColor: ColonyPigmentationAnalysisKit.RGBColor
    
    @Option(default: 0.15, help: "A value between 0 and 1 that represents how sensitive the background removal is. A higher value means the pixels must be more different from the background to be considered foreground. A lower value means colors more different from `background-chrome-key-color` will still be considered background.")
    var backgroundChromaKeyThreshold: Double
    
    @Option(default: .init(r: 128, g: 61, b: 51), help: "An RGB color to compare pixels against when looking for pigmentation")
    var pigmentationColor: ColonyPigmentationAnalysisKit.RGBColor
    
    @Option(default: 0.436, help: "A minimum level of pigmentation that is considered 'background noise' and is subtracted from all values")
    var baselinePigmentation: Double
    
    @Option(default: nil, help: "A file to read a pigmentation histogram for to use as baseline values. If specified, this takes precendence over --baseline-pigmentation. It must be a file with the same format as a csv output by this program")
    var baselinePigmentationHistogramFilePath: String?

    @Option(default: 200, help: "Output the pigmentation histogram csv by interpolating to this many values")
    var pigmentationHistogramSampleCount: Int
    
    @Option(name: .customLong("pigmentation-roi-height"), default: 0.2, help: "A value between 0 and 1 to reduce the height of the area considered to calculate pigmentation")
    var pigmentationAreaOfInterestHeightPercentage: Double
    
    @Flag(name: .long, default: true, inversion: .prefixedNo, help: "Whether to utilize as many cores as possible to analyze images in parallel")
    var parallelize: Bool
    
    func run() throws {
        guard !images.isEmpty else {
            throw ValidationError("No images specified")
        }
        
        logger.info("\("Analyzing \(String(images.count).onBlack()) images".blue())")
        
        try saveCurrentConfigurationToFile()
        
        let pigmentationValuesToSubtract = try baselinePigmentationSamples()?.map { $0.averagePigmentation }
        if let pigmentationValuesToSubtract = pigmentationValuesToSubtract {
            precondition(pigmentationValuesToSubtract.count == pigmentationHistogramSampleCount, "The number of pigmentation samples to subtract provided via --baseline-pigmentation-histogram-file-path needs to match --pigmentation-histogram-sample-count")
        }
        
        let queue = DispatchQueue(label: "colony-analysis-queue", qos: .userInitiated, attributes: parallelize ? .concurrent : [], autoreleaseFrequency: .inherit, target: nil)
        
        var lastCaughtError: Swift.Error?
        
        for (index, imagePath) in images.enumerated() {
            queue.async {
                do {
                    try self.analyzeImage(atPath: imagePath, withPigmentationValuesToSubtract: pigmentationValuesToSubtract)
                } catch {
                    lastCaughtError = error
                    logger.error("Error analyzing image \(index) (\(imagePath)): \(error)")
                }
            }
        }
        
        queue.async(flags: .barrier) {
            do {
                try measure(name: "Average pigmentation across images") {
                    let averagedPigmentationSamples = PigmentationSample.averaging(Self.pigmentationSamples)
                    try averagedPigmentationSamples.save(toPath: self.outputPath.appending("average_pigmentation.\([PigmentationSample].fileExtension)"))
                    
                    try pigmentationSeriesTask.run(withInput: averagedPigmentationSamples, configuration: ()).save(toPath: self.outputPath.appending("average_pigmentation_1d.csv"))
                    
//                    let minPigmentation = PigmentationSample.minAveragePigmentation(Self.pigmentationSamplesWithoutBaseline)
//                    try CSV(contents: "\(minPigmentation)").save(toPath: self.outputPath.appending("min_pigmentation.txt"))
                }
            } catch {
                lastCaughtError = error
            }
        
            logger.info("\("Finished!".lightGreen().bold())")
            
            Self.exit(withError: lastCaughtError)
        }
        
        RunLoop.main.run()
    }
}

Main.main()

private extension Main {
    static var pigmentationSamples: [[PigmentationSample]] = []
    static var pigmentationSamplesWithoutBaseline: [[PigmentationSample]] = []
    
    func analyzeImage(atPath imagePath: String, withPigmentationValuesToSubtract pigmentationValuesToSubtract: [Double]?) throws {
        let imageName = ((imagePath as NSString).lastPathComponent as NSString).deletingPathExtension
        
        try measure(name: imageName) {
            let taskRunner = TaskRunner(inputImageName: imageName, outputDirectory: outputPath, detailedProgressOutput: detailedProgress)

            let image = try taskRunner.run(
                loadImageTask,
                withInput: imagePath,
                configuration: .init(downscaleFactor: downscaleFactor),
                artifactDirectory: "OriginalImages"
            )
            
            let colonyMask = try taskRunner.run(
                maskColonyTask,
                withInput: image,
                configuration: .init(backgroundChromaKeyColor: backgroundChromaKeyColor, backgroundChromaKeyThreshold: backgroundChromaKeyThreshold),
                artifactDirectory: "MaskedColonies"
            )
            
            try taskRunner.run(
                removeBackgroundTask,
                withInput: (image, colonyMask),
                configuration: (),
                artifactDirectory: "BackgroundRemoved"
            )
            
            try taskRunner.run(
                drawPigmentationTask,
                withInput: (image, colonyMask),
                configuration: .init(pigmentationColor: pigmentationColor, baselinePigmentation: baselinePigmentation),
                artifactDirectory: "DrawnPigmentation"
            )
            
            try taskRunner.run(
                drawPigmentationTask,
                withInput: (image, colonyMask),
                configuration: .init(pigmentationColor: pigmentationColor, baselinePigmentation: baselinePigmentation,
                                     pigmentationValuesToSubtract: pigmentationValuesToSubtract,
                                     areaOfInterestHeightPercentage: pigmentationAreaOfInterestHeightPercentage,
                                     cropWithinAreaOfInterest: true),
                artifactDirectory: "DrawnPigmentationROI"
            )
            
            try taskRunner.run(
                pigmentationHistogramTask,
                withInput: (image, colonyMask),
                configuration: .init(pigmentationColor: pigmentationColor, baselinePigmentation: baselinePigmentation, pigmentationValuesToSubtract: nil, pigmentationAreaOfInterestHeightPercentage: pigmentationAreaOfInterestHeightPercentage, horizontalSamples: nil),
                artifactDirectory: "RawPigmentationHistogram"
            )
            
            let sampledPigmentation = try taskRunner.run(
                pigmentationHistogramTask,
                withInput: (image, colonyMask),
                configuration: .init(pigmentationColor: pigmentationColor, baselinePigmentation: baselinePigmentation, pigmentationValuesToSubtract: pigmentationValuesToSubtract, pigmentationAreaOfInterestHeightPercentage: pigmentationAreaOfInterestHeightPercentage, horizontalSamples: pigmentationHistogramSampleCount),
                artifactDirectory: "SampledPigmentationHistogram"
            )
            
//            let sampledPigmentationWithoutBaseline = try taskRunner.run(
//                pigmentationHistogramTask,
//                withInput: (image, colonyMask),
//                configuration: .init(pigmentationColor: pigmentationColor, baselinePigmentation: 0, pigmentationValuesToSubtract: nil, pigmentationAreaOfInterestHeightPercentage: pigmentationAreaOfInterestHeightPercentage, horizontalSamples: pigmentationHistogramSampleCount),
//                artifactDirectory: "NoBaselineSampledPigmentationHistogram"
//            )
                
            DispatchQueue.main.sync {
                Self.pigmentationSamples.append(sampledPigmentation)
//                Self.pigmentationSamplesWithoutBaseline.append(sampledPigmentationWithoutBaseline)
            }
            
            try taskRunner.run(
                pigmentationSeriesTask,
                withInput: sampledPigmentation,
                configuration: (),
                artifactDirectory: "PigmentationSeries"
            )
        }
    }
    
    private func baselinePigmentationSamples() throws -> [PigmentationSample]? {
        return try baselinePigmentationHistogramFilePath.map {
            return try readPigmentationHistogram(at: $0)
        }
    }
}

extension Main {
    func validate() throws {
        var outputPathIsDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: outputPath, isDirectory: &outputPathIsDirectory),
            outputPathIsDirectory.boolValue
            else { throw ValidationError("--output-path \"\(outputPath)\" doesn't exist or is not a folder") }
        
        guard downscaleFactor > 0 && downscaleFactor <= 1 else { throw ValidationError("downscale-factor must be a value between 0 and 1. Got \(downscaleFactor) instead") }
        guard (0...1).contains(backgroundChromaKeyThreshold) else { throw ValidationError("background-chroma-key-threshold must be a value between 0 and 1. Got \(backgroundChromaKeyThreshold) instead") }
        
        guard (0...1).contains(baselinePigmentation) else {
            throw ValidationError("baseline-pigmentation must be a value between 0 and 1. Got \(baselinePigmentation) instead")
        }
        
        if let baselinePigmentationHistogramFilePath = baselinePigmentationHistogramFilePath {
            guard FileManager.default.fileExists(atPath: baselinePigmentationHistogramFilePath) else {
                throw ValidationError("--baseline-pigmentation-histogram-file-path \"\(baselinePigmentationHistogramFilePath)\" doesn't exist")
            }
        }
        
        guard (0...1).contains(pigmentationAreaOfInterestHeightPercentage) else { throw ValidationError("pigmentation-roi-height must be a value between 0 and 1. Got \(pigmentationAreaOfInterestHeightPercentage) instead") }
    }
    
    static var configuration: CommandConfiguration {
        return CommandConfiguration(
            commandName: "./run",
            abstract: "A command line interface to ColonyPigmentationAnalysisKit which implements a pipeline of actions on the images passed in the --images parameter.",
            discussion: "See README.md for more information.",
            version: "v1.0",
            shouldDisplay: true)
    }
}

private extension Main {
    func saveCurrentConfigurationToFile() throws {
        let configuration = """
        Date: \(Date())
        Downscale Factor: \(downscaleFactor)
        Background Chroma Key Color: \(backgroundChromaKeyColor)
        Background Chroma Key Threshold: \(backgroundChromaKeyThreshold)
        Pigmentation Color: \(pigmentationColor)
        Pigmentation Histogram Sample Count: \(pigmentationHistogramSampleCount)
        Pigmentation Area of Interest Height Percentage: \(pigmentationAreaOfInterestHeightPercentage)
        Images (\(images.count)): \(images.joined(separator: ", "))
        Baseline Pigmentation: \(baselinePigmentation)
        Baseline Pigmentation Histogram Contents:\n\(try baselinePigmentationSamples()?.csv.contents ?? "N/A")
        """
        
        let path = outputPath.appending("parameters.txt")
        try configuration.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
}

extension ColonyPigmentationAnalysisKit.RGBColor: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rgbHexString: argument)
    }
    
    public var defaultValueDescription: String {
        return hexString
    }
}
