//
//  CreditsView.swift
//  SwiftAA
//
//  Created by Kihron on 2/19/24.
//

import SwiftUI
import CachedAsyncImage

struct CreditsView: View {
    var body: some View {
        VStack {
            SettingsCardView {
                VStack {
                    CreditsEntryView(name: "Slackow", role: "Developer", icon: "wrench.adjustable.fill", color: .teal)
                    
                    CreditsEntryView(name: "Kihron", role: "Developer", icon: "wrench.adjustable.fill", color: .orange)
                    
                    CreditsEntryView(name: "nealxm", role: "Beta Tester", icon: "atom", color: .green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            SettingsLabel(title: "Support Us")
                .padding(.top, 5)
            
            SettingsCardView {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundStyle(.pink)
                    
                    Text(.init("If you're finding SlackowWall helpful and would like to support its development, consider making a donation on our [Ko-fi](https://ko-fi.com/kscode)."))
                        .tint(.pink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private func getAvatarURL(_ name: String) -> URL? {
        return URL(string: "https://minotar.net/helm/\(name)/32")
    }
}

#Preview {
    CreditsView()
}
