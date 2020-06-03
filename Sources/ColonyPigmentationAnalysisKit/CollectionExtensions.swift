//
//  CollectionExtensions.swift
//  ColonyPigmentationAnalysisKit
//
//  Created by Javier Soto on 1/12/20.
//  Copyright © 2020 Javier Soto. All rights reserved.
//

internal extension Collection where Element == Double {
    var average: Double {
        var total: Double = 0
        var count = 0
        
        for element in self {
            total += element
            count += 1
        }
        
        return count > 0 ? total / Double(count) : 0
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
