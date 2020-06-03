// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColonyPigmentationAnalysis",
    products: [
        .library(
            name: "ColonyPigmentationAnalysisKit",
            type: .static,
            targets: ["ColonyPigmentationAnalysisKit"]
        ),
        .executable(name: "ColonyPigmentationAnalysis", targets: ["ColonyPigmentationAnalysis"])
    ],
    dependencies: [
        .package(url: "https://github.com/t-ae/swim.git", from: "3.8.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.6"),
        .package(url: "https://github.com/apple/swift-log/", from: "1.2.0"),
        .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "ColonyPigmentationAnalysis", dependencies: [
            "ColonyPigmentationAnalysisKit", 
            "ArgumentParser",
            "Logging",
            "ColorizeSwift"
            ]),
        .target(
            name: "ColonyPigmentationAnalysisKit",
            dependencies: [
                "Swim",
                "Logging",
                "ColorizeSwift"
                ]
        ),
        .testTarget(
            name: "ColonyPigmentationAnalysisKitTests",
            dependencies: ["ColonyPigmentationAnalysisKit"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
