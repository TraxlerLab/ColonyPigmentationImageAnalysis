//
//  CollectionExtensions.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 1/12/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

import Foundation

internal extension RandomAccessCollection where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        
        var total: Double = 0
        
        for element in self {
            total += element
        }
        
        return total / Double(count)
    }
    
    var standardDeviation: Double {
        guard !isEmpty else { return 0 }
        
        let mean = average
        
        let sumOfSquaredAvgDiff = map { pow($0 - mean, 2) }.reduce(0, +)
        return sqrt(sumOfSquaredAvgDiff / Double(count))
    }
}

internal extension Collection {
    func count(where test: (Element) -> Bool) -> Int {
        var total = 0
        
        for element in self where test(element) {
            total += 1
        }
        
        return total
    }
}
