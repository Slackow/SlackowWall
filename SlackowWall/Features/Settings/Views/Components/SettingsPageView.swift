//
//  SettingsPageView.swift
//  SlackowWall
//
//  Created by Kihron on 7/25/24.
//

import SwiftUI

struct SettingsPageView<Content: View>: View {
    let title: String
    let showTitle: Bool
    let isSubPage: Bool
    let shouldDisableFocus: Bool
    let content: () -> Content
    
    init(title: String, showTitle: Bool = true, isSubPage: Bool = false, shouldDisableFocus: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.showTitle = showTitle
        self.isSubPage = isSubPage
        self.shouldDisableFocus = shouldDisableFocus
        self.content = content
    }
    
    init(title: String, showTitle: Bool = true, isSubPage: Bool = false, shouldDisableFocus: Bool = true, content: Content) {
        self.title = title
        self.showTitle = showTitle
        self.isSubPage = isSubPage
        self.shouldDisableFocus = shouldDisableFocus
        self.content = { content }
    }
    
    var body: some View {
        if isSubPage {
            page
        } else {
            NavigationStack {
                page
            }
        }
    }
    
    var page: some View {
        ScrollView {
            VStack(spacing: 12) {
                content()
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .navigationTitle(showTitle ? title : "")
        .if(shouldDisableFocus) { view in
            view.removeFocusOnTap()
        }
    }
}

#Preview {
    SettingsPageView(title: "Test") {
        Text("Hi")
            .foregroundStyle(.white)
    }
    .frame(width: 500)
}
