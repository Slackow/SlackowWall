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
    let content: () -> Content
    
    init(title: String, showTitle: Bool = true, isSubPage: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.showTitle = showTitle
        self.isSubPage = isSubPage
        self.content = content
    }
    
    init(title: String, showTitle: Bool = true, isSubPage: Bool = false, content: Content) {
        self.title = title
        self.showTitle = showTitle
        self.isSubPage = isSubPage
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
        .removeFocusOnTap()
    }
}

#Preview {
    SettingsPageView(title: "Test") {
        Text("Hi")
    }
    .frame(width: 500)
}
