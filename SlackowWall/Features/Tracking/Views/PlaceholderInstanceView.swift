//
//  PlaceholderInstanceView.swift
//  SlackowWall
//
//  Created by Andrew on 4/21/25.
//

import SwiftUI

struct PlaceholderInstanceView: View {
    var instance: TrackedInstance
    @State var isHovered: Bool = true
    @State var isIndicatorHovered: Bool = false

    var instanceName: Substring {
        let result = instance.info.path.split(separator: "/").dropLast(1).last ?? "??"
        return result == "Application Support" ? "Minecraft" : result
    }

    var body: some View {
        ZStack {
            VStack {
                (NSImage(contentsOfFile: "\(instance.info.path)/icon.png")
                    .map(Image.init)
                    ?? Image("minecraft_logo"))
                    .resizable()
                    .frame(width: 120, height: 120)
                Text(#"Instance "\#(instanceName)""#)
                    .font(.title)
                    .fontWeight(.semibold)
            }
            HStack {
                if instance.info.isBoundless {
                    Image(systemName: "macwindow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.top, 8)
                        .padding(.leading, 8)
                        .popoverLabel("Using Boundless Window")

                }
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
                    //                    Button("Check/Update Mods") {
                    //                        print("Folder Not Opened")
                    //                    }
                    //                    Button("Package Submission Files") {
                    //                        print("TODO")
                    //                    }
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
            //            EyeProjectorView(instance: instance)
        }
        .frame(
            minWidth: 250, idealWidth: 600, maxWidth: 600, minHeight: 165, idealHeight: 350,
            maxHeight: 350
        )
        .background {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: 3)
                .background(.ultraThinMaterial)

        }
    }

}
