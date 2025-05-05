//
//  SettingsButtonView.swift
//  SlackowWall
//
//  Created by Kihron on 4/28/24.
//

import SwiftUI

struct SettingsButtonView<Content: View>: View {
    let title: String
    var description: String?
    var descInteractable: Bool = true
    var buttonText: String?
    var action: ()->()
    
    @State private var textHeight: CGSize = .zero
    @State private var contentHeight: CGSize = .zero
    @State private var labelHeight: CGSize = .zero
    private var content: (() -> Content)?
    
    // Initializer for simple text button
    init(title: String, description: String? = nil, buttonText: String, action: @escaping () -> Void) where Content == EmptyView {
        self.title = title
        self.description = description
        self.buttonText = buttonText
        self.action = action
    }
    
    // Initializer for custom label
    init(title: String, description: String? = nil, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.action = action
        self.content = content
    }
    
    private var alignment: VerticalAlignment {
        if contentHeight.height > labelHeight.height {
            return .top
        } else {
            return description != nil && textHeight.height > 20 ? .top : .center
        }
    }
    
    var body: some View {
        HStack(alignment: alignment) {
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
            .modifier(SizeReader(size: $labelHeight))
            
            if let content {
                Button(action: action) {
                    content()
                }
                .modifier(SizeReader(size: $contentHeight))
            } else if let buttonText {
                Button(action: action) {
                    Text(buttonText)
                }
                .padding(.leading)
            }
        }
        .animation(nil, value: textHeight)
    }
}

#Preview {
    VStack {
        SettingsButtonView(title: "Test Option", description: "This is an example setting description for this button.", buttonText: "Action", action: { print("Example.") })
            .padding()
        
        SettingsButtonView(title: "Test Option", description: "This is an example setting description for this button.", action: { print("Example.") }) {
                Image(systemName: "xmark")
        }
        .padding()
    }
}
