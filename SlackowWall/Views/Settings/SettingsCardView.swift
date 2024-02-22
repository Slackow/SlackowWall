//
//  SettingsCardView.swift
//  SlackowWall
//
//  Created by Kihron on 1/19/23.
//

import SwiftUI

struct SettingsCardView<Content: View>: View {
    var title: String?
    var padding: CGFloat?
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = title {
                Text(title)
                    .padding(.leading, 10)
            }

            content()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray), lineWidth: 1)
                )
        }
        .padding(padding ?? 0)
    }
}

struct SettingsCardView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsCardView() {
            Text("A")
        }
    }
}
