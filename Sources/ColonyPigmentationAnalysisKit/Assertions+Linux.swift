//
//  Assertions+Linux.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 5/31/20.
//

import Foundation

// Override assertion methods in order to get output in Linux before crashing.
// Otherwise, we just see `Illegal instruction     (core dumped)`

@inlinable
public func assert(_ condition: Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    if !condition {
        assertionFailure(message(), file: file, line: line)
    }
}

@inlinable
public func assertionFailure(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    logger.critical("\(file):\(line) assertionFailure: \(message())")
    Swift.assertionFailure(message(), file: file, line: line)
}

@inlinable
public func fatalError(_ message: String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    logger.critical("\(file):\(line) fatalError: \(message)")
    Swift.fatalError(message, file: file, line: line)
}

@inlinable
public func preconditionFailure(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
    logger.critical("\(file):\(line) preconditionFailure: \(message)")
    Swift.preconditionFailure(message, file: file, line: line)
}

@inlinable
public func precondition(_ condition: Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    if !condition {
        ColonyPigmentationAnalysisKit.preconditionFailure(message(), file: file, line: line)
    }
}
