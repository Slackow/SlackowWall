//
//  PlaceholderInstanceView.swift
//  SlackowWall
//
//  Created by Andrew on 4/21/25.
//

import SwiftUI

struct PlaceholderInstanceView: View {
    var instance: TrackedInstance
    @State private var isHovered: Bool = true
    @State private var isIndicatorHovered: Bool = false
    @State private var isModMenuOpen: Bool = false
    @StateObject private var deletionModel = WorldDeletionViewModel()

    var body: some View {
        ZStack {
            VStack {
                Image(
                    NSImage(contentsOfFile: "\(instance.info.path)/icon.png").flatMap {
                        .nsImage($0)
                    } ?? .asset("minecraft_logo")
                )
                .resizable()
                .frame(width: 120, height: 120)

                Text(#"Instance "\#(instance.name)""#)
                    .font(.title)
                    .fontWeight(.semibold)
            }
            HStack {
                Spacer()
                    .frame(maxWidth: .infinity)

                Menu("") {
                    Button("Focus Instance") {
                        WindowController.focusWindow(instance.pid)
                    }
                    if !instance.info.path.isEmpty {
                        Button("Open MC Folder") {
                            NSWorkspace.shared.selectFile(
                                nil, inFileViewerRootedAtPath: instance.info.path)
                        }
                    }
                    Button("Clear Worlds") {
                        deletionModel.prepareDeletion(instancePath: instance.info.path)
                    }
                    Button("View Mods") {
                        isModMenuOpen = true
                    }
                    Button("Kill Instance") {
                        TrackingManager.shared.kill(instance: instance)
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: 19, height: 19)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaleEffect(1.5)
                .padding(.trailing, 10)
                .padding(.top, 10)

            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .opacity(isHovered ? 1 : 0)
                .animation(.easeInOut.delay(0.15).speed(2), value: isHovered)

            HStack {
                Button("View Mods") {
                    isModMenuOpen = true
                }
                Button("Fix NinjabrainBot") {
                    do {
                        let results = try NinjabrainAdjuster.get(instance: instance)
                        LogManager.shared.appendLog(results)
                        // imagine a sheet or something to determine which options the user wants enabled (especially for recommended)
                        // so this fix call won't be right below in the final thing
                        var fixFilter = [NinjabrainAdjuster.NinBotSetting]()
                        fixFilter += results.breaking
                        fixFilter += results.recommend
                        try NinjabrainAdjuster.fix(instance: instance, fixFilter: fixFilter)
                        LogManager.shared.appendLog("Successfully fixed instance!")
                    } catch {
                        LogManager.shared.appendLog(error)
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, 5)
                .padding(.leading, 5)

            DeletionProgressView(model: deletionModel)
        }
        .frame(
            minWidth: 250, idealWidth: 600, maxWidth: 600, minHeight: 205, idealHeight: 350,
            maxHeight: 350
        )
        .background {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: 3)
                .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $isModMenuOpen) {
            ModMenu(instance: instance)
        }
    }
}
