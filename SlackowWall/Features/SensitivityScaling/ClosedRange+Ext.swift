//
//  ClosedRange+Ext.swift
//  SlackowWall
//
//  Created by Andrew on 6/5/25.
//

extension ClosedRange where Bound: Comparable {

    public func clamped(value: Bound) -> Bound {
        return Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
