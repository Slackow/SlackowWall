//
//  ToolbarStopView.swift
//  SlackowWall
//
//  Created by Kihron on 7/24/24.
//

import SwiftUI

struct ToolbarStopView: View {
    @ObservedObject private var instanceManager = InstanceManager.shared
    
    var body: some View {
        Button(action: { instanceManager.stopAll() }) {
            if #available(macOS 14.0, *) {
                Image(systemName: "stop.fill")
                    .foregroundColor(.red)
                    .frame(width: 20, height: 20)
                    .symbolEffect(.pulse, options: .repeating, value: instanceManager.isStopping)
            } else {
                Image(systemName: "stop.fill")
                    .foregroundColor(.red)
                    .frame(width: 20, height: 20)
            }
        }
        .disabled(instanceManager.isStopping)
    }
}

#Preview {
    ToolbarStopView()
}
