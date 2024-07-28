//
//  SettingsLinkView.swift
//  SlackowWall
//
//  Created by Kihron on 7/25/24.
//

import SwiftUI

struct SettingsLinkView<Destination: View>: View {
    let title: String
    var description: String?
    let destination: () -> Destination
    
    init(title: String, description: String? = nil, @ViewBuilder destination: @escaping () -> Destination) {
        self.title = title
        self.description = description
        self.destination = destination
    }
    
    init(title: String, description: String? = nil, destination: Destination) {
        self.title = title
        self.description = description
        self.destination = { destination }
    }
    
    var body: some View {
        NavigationLink {
            SettingsPageView(title: title, isSubPage: true, content: destination)
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                    
                    if let description = description {
                        Text(.init(description))
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.trailing, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
            }
            .padding(.vertical, description != nil ? 0 : 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        SettingsLinkView(title: "Sample Title", description: "This is an example description.") {
            Text("Hi")
        }
        
        SettingsLinkView(title: "Sample Title", destination: Text("Hi"))
    }
    .padding()
}
