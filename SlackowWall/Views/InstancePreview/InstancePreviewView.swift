//
//  InstancePreviewView.swift
//  SlackowWall
//
//  Created by Kihron on 1/11/23.
//

import SwiftUI
import ScreenCaptureKit

struct InstancePreviewView: View {
    @ObservedObject public var a = InstancePreviewViewModel()
    var body: some View {
        Text("as")
    }
}

struct InstancePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InstancePreviewView()
    }
}
