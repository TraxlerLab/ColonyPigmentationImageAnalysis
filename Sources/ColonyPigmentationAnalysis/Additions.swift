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

extension Array where Element == PigmentationSample {
    fileprivate static let csvHeader = "x, average, stddev, columns"
    
    var csv: CSV {
        let header = "\(Self.csvHeader)\n"
        let contents = map({ "\($0.x),\($0.averagePigmentation),\($0.standardDeviation),\($0.includedColumnIndices.map(String.init).joined(separator: "-"))" }).joined(separator: "\n")
        
        return CSV(contents: header + contents)
    }
}

extension Array: StorableInDisk where Element == PigmentationSample {
    static var fileExtension: String { "csv" }
    
    func save(toPath path: String) throws {
        try csv.save(toPath: path)
    }
}

func createDirectory(_ directory: String) throws {
    do {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: directory), withIntermediateDirectories: true)
    } catch {
        throw TaskError.failedToCreateResultDirectory(path: directory, underlyingError: error)
    }
}

func readPigmentationHistogram(at path: String) throws -> [PigmentationSample] {
    enum InvalidCSVFormatError: CustomNSError, LocalizedError {
        case invalidHeader(contents: String)
        case invalidNumberOfRows(Int)
        case invalidRowFormat(rowIndex: Int, contents: String)
        case invalidValueFormat(expectedType: Any.Type, value: String)
            
        static let errorDomain = "InvalidCSVFormatError"
        
        var errorDescription: String? {
            switch self {
            case let .invalidHeader(contents): return "Invalid header: \(contents). Expected \"\([PigmentationSample].csvHeader)\""
            case let .invalidNumberOfRows(rows): return "Invalid number of rows: \(rows). Expected > 1"
            case let .invalidRowFormat(rowIndex, contents): return "Invalid row format at \(rowIndex): \(contents)"
            case let .invalidValueFormat(expectedType, value): return "Invalid value format: \(value). Expected \(expectedType)"
            }
        }
    }
    
    let contents = try String(contentsOfFile: path)
    let rows = contents.split(separator: "\n")
    guard rows.count > 1 else {
        throw InvalidCSVFormatError.invalidNumberOfRows(rows.count)
    }
    
    guard rows[0] == [PigmentationSample].csvHeader else {
        throw InvalidCSVFormatError.invalidHeader(contents: String(rows[0]))
    }
    
    let rowsWithoutHeader = rows.dropFirst()
    
    return try rowsWithoutHeader.enumerated().map { (index, row) in
        let columns = row.split(separator: ",")
        guard columns.count == 4 else {
            throw InvalidCSVFormatError.invalidRowFormat(rowIndex: index, contents: String(row))
        }
        
        guard let x = Double(columns[0]) else {
            throw InvalidCSVFormatError.invalidValueFormat(expectedType: Double.self, value: String(columns[0]))
        }
        guard let averagePigmentation = Double(columns[1]) else {
            throw InvalidCSVFormatError.invalidValueFormat(expectedType: Double.self, value: String(columns[1]))
        }
        
        guard let standardDeviation = Double(columns[2]) else {
            throw InvalidCSVFormatError.invalidValueFormat(expectedType: Double.self, value: String(columns[2]))
        }
        let includedColumnIndices = try columns[3].split(separator: "-").map { (value: Substring) throws -> Int in
            guard let intValue = Int(value) else {
                throw InvalidCSVFormatError.invalidValueFormat(expectedType: Int.self, value: String(value))
            }
            return intValue
        }
        
        return PigmentationSample(x: x, averagePigmentation: averagePigmentation, standardDeviation: standardDeviation, includedColumnIndices: includedColumnIndices)
    }
}
