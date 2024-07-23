//
//  TrackedInstanceView.swift
//  SlackowWall
//
//  Created by Kihron on 3/13/24.
//

import SwiftUI

struct TrackedInstanceView: View {
    @ObservedObject private var captureGrid = CaptureGrid.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    
    @ObservedObject var instance: TrackedInstance
    
    private var hasStreamError: Bool {
        return instance.stream.streamError != nil
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            CapturePreviewView(instance: instance)
                .background {
                    Text("Instance \(instance.instanceNumber)")
                        .padding(.trailing, 4)
                        .opacity(captureGrid.showInfo ? 1 : 0)
                }
                .opacity(hasStreamError ? 0 : 1)
                .overlay {
                    StreamErrorView(error: instance.stream.streamError)
                }
                .animation(.easeInOut, value: instance.stream.streamError)
            
            VStack(alignment: .trailing, spacing: 0) {
                if instance.isLocked {
                    Image(systemName: "lock.fill")
                        .scaleEffect(CGSize(width: 2, height: 2))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)
                        .opacity(captureGrid.showInfo ? 1 : 0)
                        .animation(.easeInOut, value: captureGrid.showInfo)
                }
                
                if profileManager.profile.showInstanceNumbers {
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
            .opacity(captureGrid.showInfo ? 1 : 0)
            .animation(.easeInOut, value: captureGrid.showInfo)
            .animation(.easeInOut, value: profileManager.profile.showInstanceNumbers)
            .animation(.bouncy, value: instance.isLocked)
        }
        .disabled(instance.wasClosed || hasStreamError)
        .opacity(instance.wasClosed ? 0 : 1)
        .animation(.easeInOut, value: instance.wasClosed)
    }
}
