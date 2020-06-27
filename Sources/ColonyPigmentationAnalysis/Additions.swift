//
//  Additions.swift
//  ColonyPigmentationAnalysis
//
//  Created by Javier Soto on 5/28/20.
//

import Foundation
import ColonyPigmentationAnalysisKit
import ColorizeSwift

@discardableResult
func measure<T>(name: String, _ f: () throws -> T) rethrows -> T {
    logger.info("\("[\(name)] Starting".dim())")
    
    let before = Date()
    let result = try f()
    let after = Date()
    
    name.green().withCString { str in
        logger.info("\(String(format: "[%s] \("Finished".darkGray().bold().onGreen()) in %.2fs", str, after.timeIntervalSince(before)))")
    }
    
    return result
}

extension String {
    func appendingPathComponent(_ pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
}

struct CSV {
    let contents: String
}

extension ImageMap: StorableInDisk {
    static var fileExtension: String { "jpg" }
}

extension MaskBitMap: StorableInDisk {
    static var fileExtension: String { "jpg" }
}

extension CSV: StorableInDisk {
    static var fileExtension: String { "csv" }
    
    func save(toPath path: String) throws {
        try contents.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
}

extension Array: StorableInDisk where Element == PigmentationSample {
    static var fileExtension: String { "csv" }
    
    func save(toPath path: String) throws {
        let header = "x, average, stddev\n"
        let contents = map({ "\($0.x),\($0.averagePigmentation),\($0.standardDeviation)" }).joined(separator: "\n")
        
        try CSV(contents: header + contents).save(toPath: path)
    }
}

func createDirectory(_ directory: String) throws {
    do {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: directory), withIntermediateDirectories: true)
    } catch {
        throw TaskError.failedToCreateResultDirectory(path: directory, underlyingError: error)
    }
}
