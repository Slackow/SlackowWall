//
//  CaptureErrorView.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

struct CaptureErrorView: View {
    var error: StreamError?
    
    var body: some View {
        if error != nil {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red)
                    .opacity(0.5)
                
                GeometryReader { geo in
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width / 4, height: geo.size.height / 3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }
}

#Preview {
    CaptureErrorView(error: .unknown(errorCode: 0))
}
