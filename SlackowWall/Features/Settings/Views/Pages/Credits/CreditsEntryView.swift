//
//  CreditsEntryView.swift
//  SwiftAA
//
//  Created by Kihron on 2/22/24.
//

import SwiftUI
import CachedAsyncImage

struct CreditsEntryView: View {
    let name: String
    let role: String
    var icon: String?
    var color: Color?
    
    var body: some View {
        HStack {
            CachedAsyncImage(url: getAvatarURL(name)) { image in
                image
            } placeholder: {
                Image(name)
            }
            .frame(width: 32)
            .clipShape(.rect(cornerRadius: 2))
            
            Text("\(name) - \(role)")
            
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(color ?? .white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getAvatarURL(_ name: String) -> URL? {
        return URL(string: "https://minotar.net/helm/\(name)/32")
    }
}

#Preview {
    CreditsEntryView(name: "Kihron", role: "Developer")
}
