//
//  SizeReader.swift
//  SwiftAA
//
//  Created by Kihron on 3/2/24.
//

import SwiftUI

struct SizeReader: ViewModifier {
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geometryProxy in
                Color.clear
                    .onAppear {
                        size = geometryProxy.size
                    }
                    .onChange(of: geometryProxy.size) { newSize in
                        size = newSize
                    }
                
            }
        )
    }
}
