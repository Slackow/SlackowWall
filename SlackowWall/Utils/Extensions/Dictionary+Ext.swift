//
//  Dictionary+Ext.swift
//  SlackowWall
//
//  Created by Kihron on 3/13/24.
//

import SwiftUI

extension Dictionary where Value : Hashable {
    
    func swapKeyValues() -> [Value : Key] {
        var newDict = [Value : Key]()
        for (key, value) in self {
            newDict[value] = key
        }
        return newDict
    }
}
