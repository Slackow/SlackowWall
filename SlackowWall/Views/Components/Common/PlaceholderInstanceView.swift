//
//  PlaceholderInstanceView.swift
//  SlackowWall
//
//  Created by Andrew on 4/21/25.
//

import SwiftUI

struct PlaceholderInstanceView: View {
    var instance: TrackedInstance
    @State var isHovered: Bool = false
    var body: some View {
        ZStack {
            VStack {
                if let nsImage = NSImage(contentsOfFile: "\(instance.info.path)/icon.png") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 120, height: 120)
                }
                Text("Instance \"\(instance.info.path.split(separator: "/").dropLast(1).last ?? "??")\"")
                    .font(.title)
                    .fontWeight(.semibold)
            }
            HStack {
//                Image(systemName: "chevron.down.circle.fill")
//                    .resizable()
//                    .frame(width: 30, height: 30)
//                    .padding(.trailing, 4)
//                    .padding(.top, 4)
//                    .contextMenu {
//                        Button("Open Folder") {
//                            print("Folder Opened")
//                        }
//                        Button("Open Folder2") {
//                            print("Folder Not Opened")
//                        }
//                    }
                Menu ("") {
                    Button("Focus Instance") {
                        WindowController.focusWindow(instance.pid)
                    }
                    Button("Open MC Folder") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: instance.info.path)
                    }
//                    Button("Check/Update Mods") {
//                        print("Folder Not Opened")
//                    }
//                    Button("Package Submission Files") {
//                        print("TODO")
//                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: 19, height: 24)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaleEffect(1.5)
                .padding(.trailing, 9)
                .padding(.top, 10)
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .opacity(isHovered ? 1 : 0)
            .animation(.easeInOut.delay(0.15).speed(2), value: isHovered)
        }
        .frame(width: 600, height: 350)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .stroke(.gray, lineWidth: 3)
        }
        .onHover(perform: {isHovered = $0})
    }
    
}
