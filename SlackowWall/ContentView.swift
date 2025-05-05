//
//  ContentView.swift
//  SlackowWall
//
//  Created by Andrew on 8/1/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var gridManager = GridManager.shared
    @ObservedObject private var updateManager = UpdateManager.shared
    
    var body: some View {
        GeometryReader { geo in
            CaptureGridView()
                .sheet(isPresented: $updateManager.appWasUpdated) {
                    UpdateMessageView(title: "App Updated")
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    gridManager.isActive = true
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                    gridManager.isActive = false
                }
        }
        .background(.black)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
