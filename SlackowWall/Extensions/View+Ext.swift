//
//  View+Ext.swift
//  SlackowWall
//
//  Created by Kihron on 5/2/24.
//

import SwiftUI

extension View {
    func boundsCheck(isOutside: Binding<Bool>) -> some View {
        modifier(BoundsChecker(isOutside: isOutside))
    }
}