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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            CapturePreviewView(instance: instance)
                .background {
                    Text("Instance \(instance.instanceNumber)")
                        .padding(.trailing, 4)
                        .opacity(captureGrid.showInfo ? 1 : 0)
                }
            
            if instance.isLocked {
                Image(systemName: "lock.fill")
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 27)
                    .opacity(captureGrid.showInfo ? 1 : 0)
                    .animation(.easeInOut, value: captureGrid.showInfo)
            }
            
            VStack {
                if profileManager.profile.showInstanceNumbers {
                    Text("\(instance.instanceNumber)")
                        .foregroundColor(.white)
                        .padding(4)
                }
            }
            .opacity(captureGrid.showInfo ? 1 : 0)
            .animation(.easeInOut, value: captureGrid.showInfo)
            .animation(.easeInOut, value: profileManager.profile.showInstanceNumbers)
            .animation(.easeInOut, value: instance.isLocked)
        }
    }
}
