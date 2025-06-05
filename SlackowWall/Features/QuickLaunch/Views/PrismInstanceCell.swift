//
//  PrismInstanceCell.swift
//  SlackowWall
//
//  Created by Andrew on 5/30/25.
//

import SwiftUI

struct PrismInstanceCell: View {
    let instance: PrismInstance
    let isFavourite: Bool
    let toggleFavourite: (PrismInstance) -> Void
    let launch: (PrismInstance) -> Void
    @State var isHovered: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: instance.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .overlay(isHovered ? .gray.opacity(0.2) : .clear)
                .background(.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onHover(perform: { isHovered = $0 })
                .onTapGesture {
                    launch(instance)
                }

            Text(instance.name)
                .font(.title3)
                .truncationMode(.tail)
                .frame(height: 20)

            HStack(spacing: 12) {
                Button(action: { toggleFavourite(instance) }) {
                    Image(systemName: isFavourite ? "star.fill" : "star")
                }
                .buttonStyle(.plain)
            }
        }
        .mask(RoundedRectangle(cornerRadius: 12).padding(-10))
        .padding(10)
    }
}
