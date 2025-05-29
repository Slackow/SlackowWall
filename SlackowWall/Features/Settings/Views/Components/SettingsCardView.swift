//
//  SettingsCardView.swift
//  SlackowWall
//
//  Created by Kihron on 1/19/23.
//

import SwiftUI

struct SettingsCardView<Content: View>: View {
    var padding: CGFloat?
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
                .padding(padding ?? 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.gray.opacity(0.05))

                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray), lineWidth: 0.5)
                    }
                )
        }
    }
}

struct SettingsCardView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsCardView {
            Text("A")
        }
    }
}
