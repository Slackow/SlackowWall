//
//  BehaviorSettings.swift
//  SlackowWall
//
//  Created by Andrew on 4/28/24.
//

import SwiftUI

struct DimensionCardView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    
    var name: String
    var description: String?
    var isGameplayMode: Bool = false
    
    @Binding var x: Int?
    @Binding var y: Int?
    @Binding var width: Int?
    @Binding var height: Int?
    
    private var invalidDimension: Bool {
        return width == nil || height == nil
    }
    
    private var containsDimensions: Bool {
        return width ?? 0 > 0 || height ?? 0 > 0
    }
    
    private var outsideWindowFrame: Bool {
        guard let screen = NSScreen.main?.visibleFrame else { return true }
        let screenWidth = Int(screen.width)
        let screenHeight = Int(screen.height)
        
        return screenWidth >= (width ?? 0) && screenHeight >= (height ?? 0)
    }
    
    private var hasResetDimensions: Bool {
        return (profileManager.profile.baseWidth ?? 0) > 0 && (profileManager.profile.baseHeight ?? 0) > 0
    }
    
    var body: some View {
        SettingsCardView {
            Form {
                VStack(spacing: 8) {
                    VStack(spacing: 3) {
                        Text("\(name) Mode")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let description = description {
                            Text(.init(description))
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 2)
                        }
                    }
                    
                    HStack(spacing: 24) {
                        HStack {
                            TextField("W", value: $width, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .foregroundStyle(!outsideWindowFrame ? .red : .primary)
                                .frame(width: 80)
                            
                            TextField("H", value: $height, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .foregroundStyle(!outsideWindowFrame ? .red : .primary)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            TextField("X", value: $x, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            TextField("Y", value: $y, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    HStack {
                        if !isGameplayMode && !hasResetDimensions && containsDimensions {
                            Text("Missing Gameplay Dimensions")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .fontWeight(.semibold)
                        }
                        
                        Button(action: scaleToMonitor) {
                            Text("Scale to Monitor")
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .disabled(invalidDimension || outsideWindowFrame)
                        
                        Button(action: centerWindows) {
                            Text("Center")
                        }
                        .disabled(invalidDimension)
                    }
                }
            }
            .animation(.easeInOut, value: hasResetDimensions)
            .animation(.easeInOut, value: containsDimensions)
        }
    }
    
    private func scaleToMonitor() {
        if let s = NSScreen.main?.visibleFrame.size,
           let width = width, let height = height,
           Int(s.width) < width || Int(s.height) < height {
            let scale = max(CGFloat(width)/s.width, CGFloat(height)/s.height)
            self.width = Int(CGFloat(width) / scale)
            self.height = Int(CGFloat(height) / scale)
            if let x = x {
                self.x = Int(CGFloat(x) / scale)
            }
            if let y = y {
                self.y = Int(CGFloat(y) / scale)
            }
        }
    }
    
    private func centerWindows() {
        if let s = NSScreen.main?.visibleFrame.size,
           let width = width, let height = height {
            x = max((Int(s.width) - width)/2, 0)
            y = max((Int(s.height) - height)/2, 0)
        }
    }
}

#Preview {
    VStack {
        let profileManager = ProfileManager.shared
        DimensionCardView(name: "Wide", x: profileManager.profile.$wideX, y: profileManager.profile.$wideY, width: profileManager.profile.$wideWidth, height: profileManager.profile.$wideHeight)
    }
    .padding(20)
}
