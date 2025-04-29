//
//  ToolbarAlert.swift
//  SwiftAA
//
//  Created by Kihron on 5/21/24.
//

import SwiftUI

struct ToolbarAlertView: View {
    @ObservedObject private var alertManager = AlertManager.shared
    @State private var showPopover: Bool = false
    
    var body: some View {
        Button(action: { showPopover.toggle() }) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .frame(width: 20, height: 20)
        }
        .popover(isPresented: self.$showPopover, arrowEdge: .bottom) {
            if let error = alertManager.alert {
                PopoverView(error: error.description)
            }
        }
        .transition(.opacity)
    }
}

struct PopoverView: View {
    @ObservedObject private var alertManager = AlertManager.shared
    @State var error: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(error)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top)
            
            if alertManager.alert == .noScreenPermission {
                Button("Open System Settings") {
                    alertManager.requestScreenRecordingPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.bottom)
            } else {
                Spacer(minLength: 0)
                    .padding(.bottom)
            }
        }
        .frame(width: 280)
    }
}

struct ToolbarAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarAlertView()
            .frame(width: 50, height: 50)
    }
}
