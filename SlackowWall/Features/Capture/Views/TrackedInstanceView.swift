//
//  TrackedInstanceView.swift
//  SlackowWall
//
//  Created by Kihron on 3/13/24.
//

import SwiftUI

struct TrackedInstanceView: View {
    @ObservedObject private var gridManager = GridManager.shared
    
    @ObservedObject var instance: TrackedInstance
    
    private var hasStreamError: Bool {
        return !Settings[\.behavior].utilityMode && instance.stream.streamError != nil
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if Settings[\.behavior].utilityMode {
                PlaceholderInstanceView(instance: instance)
            } else {
                CapturePreviewView(instance: instance)
                    .background {
                        Text("Instance \(instance.instanceNumber)")
                            .padding(.trailing, 4)
                            .opacity(gridManager.showInfo ? 1 : 0)
                    }
                    .opacity(hasStreamError ? 0 : 1)
                    .overlay {
                        CaptureErrorView(error: instance.stream.streamError)
                    }
                    .animation(.easeInOut, value: instance.stream.streamError)
            }
            VStack(alignment: .trailing, spacing: 0) {
                if instance.isLocked && !Settings[\.behavior].utilityMode {
                    LockIcon()
                        .frame(width: 32 * Settings[\.personalize].lockScale, height: 32 * Settings[\.personalize].lockScale)
                        .padding(.horizontal, 4)
                        .padding(.top, 6)
                        .padding(.bottom, 3)
                        .opacity(gridManager.showInfo ? 1 : 0)
                        .animation(.easeInOut, value: gridManager.showInfo)
                }
                
                if Settings[\.instance].showInstanceNumbers && !Settings[\.behavior].utilityMode {
                    ZStack {
                        Circle()
                            .fill(.ultraThickMaterial)
                            .frame(width: 16, height: 16)
                        
                        Text("\(instance.instanceNumber)")
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    .padding(4)
                }
            }
            .opacity(gridManager.showInfo ? 1 : 0)
            .animation(.easeInOut, value: gridManager.showInfo)
            .animation(.easeInOut, value: Settings[\.instance].showInstanceNumbers)
            .animation(Settings[\.personalize].lockAnimation ? .bouncy : .none, value: instance.isLocked)
        }
        .disabled(instance.wasClosed || hasStreamError)
        .opacity(instance.wasClosed ? 0 : 1)
        .animation(.easeInOut, value: instance.wasClosed)
    }
}
