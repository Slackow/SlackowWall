//
//  SettingsLabel.swift
//  SwiftAA
//
//  Created by Kihron on 9/6/23.
//

import SwiftUI

struct SettingsLabel: View {
    var title: String
    var description: String?
    var font: Font?
    
    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(font ?? .headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let description {
                Text(.init(description))
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    SettingsLabel(title: "Mode", description: "Switch between automatic window tracking or manually specifying a saves directory.", font: .body)
        .padding()
}
