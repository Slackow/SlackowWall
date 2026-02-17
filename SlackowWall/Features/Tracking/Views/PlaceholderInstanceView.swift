//
//  PlaceholderInstanceView.swift
//  SlackowWall
//
//  Created by Andrew on 4/21/25.
//

import SwiftUI

struct PlaceholderInstanceView: View {
    @ObservedObject var instance: TrackedInstance
    @State private var isHovered: Bool = true
    @State private var isIndicatorHovered: Bool = false
    @State private var isModMenuOpen: Bool = false
    @State private var isNinbotFixOpen: Bool = false
    @State private var isMinecraftFixOpen: Bool = false
    @State private var isInstanceSettingsOpen: Bool = false
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
                    .foregroundStyle(.white)
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
                    Button("Instance Settings") {
                        isInstanceSettingsOpen = true
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

            HStack(spacing: 10) {
                let isChecking = instance.ninbotIsChecking || instance.minecraftIsChecking
                let ninbotNeedsFix = instance.ninbotResults?.breaking.isEmpty == false
                let minecraftNeedsFix = instance.minecraftResults?.breaking.isEmpty == false
                let allGood =
                    instance.ninbotResults?.breaking.isEmpty == true
                    && instance.minecraftResults?.breaking.isEmpty == true

                Button("Instance Settings") {
                    isInstanceSettingsOpen = true
                }

                if isChecking {
                    Image(systemName: "circle")
                        .foregroundStyle(.gray)
                        .popoverLabel("Checking Minecraft and NinjabrainBot settings")
                } else {
                    if ninbotNeedsFix {
                        Button("Fix NinjabrainBot Settings") {
                            isNinbotFixOpen = true
                        }
                        .foregroundStyle(.red)
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(1))
                                NSApp.requestUserAttention(.criticalRequest)
                            }
                        }
                        .popover(isPresented: $isNinbotFixOpen) {
                            if let results = instance.ninbotResults {
                                NinbotFixSheet(instance: instance, results: results)
                                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))

                            } else {
                                Text("No NinjabrainBot issues found.")
                                    .padding()
                            }
                        }
                    }

                    if minecraftNeedsFix {
                        Button("Fix Minecraft Settings") {
                            isMinecraftFixOpen = true
                        }
                        .foregroundStyle(.red)
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(1))
                                NSApp.requestUserAttention(.criticalRequest)
                            }
                        }
                        .popover(isPresented: $isMinecraftFixOpen) {
                            if let results = instance.minecraftResults {
                                MinecraftAdjusterFixSheet(instance: instance, results: results)
                                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
                            } else {
                                Text("No Minecraft settings issues found.")
                                    .padding()
                            }
                        }
                    }

                    if allGood {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                            .popoverLabel(
                                "Minecraft and NinjabrainBot settings look good, refresh to revalidate.\(instance.hasMod(.retino) && NSScreen.factor > 1 && ProcessInfo.processInfo.operatingSystemVersion.majorVersion != 15 ? "\nretiNO is descreasing accuracy" : "")"
                            )
                    } else if instance.ninbotCheckError != nil || instance.minecraftCheckError != nil {
                        Image(systemName: "circle")
                            .foregroundStyle(.orange)
                            .popoverLabel(
                                "Failed to validate BoatEye settings:\n\([instance.ninbotCheckError, instance.minecraftCheckError].compactMap{$0}.joined(separator: ", "))"
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
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
        .sheet(isPresented: $isInstanceSettingsOpen) {
            InstanceSettingsView(instance: instance)
        }
        .sheet(isPresented: $isModMenuOpen) {
            ModMenu(instance: instance)
        }
        .task {
            await Task.yield()
            await instance.info.waitForModsToFinishLoading()
            if instance.ninbotResults == nil || instance.minecraftResults == nil,
                instance.shouldCheckBoateye
            {
                instance.refreshBoatEyeStatus()
            }
        }
    }
}
