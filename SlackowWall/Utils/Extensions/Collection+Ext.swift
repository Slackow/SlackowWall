//
//  Collection+Ext.swift
//  SlackowWall
//
//  Created by Andrew on 4/23/25.
//


public extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
