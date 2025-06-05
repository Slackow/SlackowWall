//
//  SettingsToggleView.swift
//  SwiftAA
//
//  Created by Kihron on 2/23/24.
//

import SwiftUI

struct SettingsToggleView: View {
    let title: String
    var description: String?
    var descInteractable: Bool = true

    @Binding var option: Bool
    @State private var textHeight: CGSize = .zero

    var body: some View {
        HStack(alignment: description != nil && textHeight.height > 20 ? .top : .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)

                if let description {
                    Text(.init(description))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.trailing, 2)
                        .allowsHitTesting(descInteractable)
                        .modifier(SizeReader(size: $textHeight))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $option)
                .labelsHidden()
                .toggleStyle(.switch)
                .padding(.leading)
                .tint(.accentColor)
        }
        .animation(nil, value: textHeight)
    }
}

#Preview {
    SettingsToggleView(
        title: "Test",
        description: "Also just a really long test string to check for multiline support.",
        option: .constant(false)
    )
    .padding()
}
