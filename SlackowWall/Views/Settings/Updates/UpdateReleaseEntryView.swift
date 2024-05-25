//
//  UpdateReleaseEntryView.swift
//  SwiftAA
//
//  Created by Kihron on 3/8/24.
//

import SwiftUI

struct UpdateReleaseEntryView: View {
    @State private var textSize: CGSize = .zero
    
    var title: String?
    @State var releaseEntry: ReleaseEntry
    
    private var message: String {
        let pattern = "(^|\\n)- "
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: releaseEntry.message.utf16.count)
        let formattedMessage = regex.stringByReplacingMatches(in: releaseEntry.message, options: [], range: range, withTemplate: "$1• ")
        
        return formattedMessage.replacingOccurrences(of: "### ", with: "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title ?? String(releaseEntry.tagName.dropFirst()))
                .foregroundStyle(.white)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor)
                }
                .padding(5)
            
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .top) {
                    Circle()
                        .fill(.white)
                        .frame(width: 12)
                    
                    if textSize.height > 20 {
                        Rectangle()
                            .frame(width: 2)
                    }
                }
                .offset(x: 8, y: 2)
                
                Text(.init(message))
                    .padding(.horizontal, 25)
                    .modifier(SizeReader(size: $textSize))
            }
        }
    }
}

#Preview {
    UpdateReleaseEntryView(releaseEntry: .init(id: 2412, tagName: "v1.1.0", publishedAt: Date.now, message: "This update is super cool!"))
}
