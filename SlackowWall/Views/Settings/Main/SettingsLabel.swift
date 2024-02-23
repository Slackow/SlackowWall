//
//  SettingsLabel.swift
//  SwiftAA
//
//  Created by Kihron on 9/6/23.
//

import SwiftUI

struct SettingsLabel: View {
    @State var title: String
    @State var description: String?
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    SettingsLabel(title: "Mode", description: "Switch between automatic window tracking or manually specifying a saves directory.")
}
