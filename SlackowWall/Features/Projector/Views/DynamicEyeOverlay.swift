//
//  DynamicEyeOverlay.swift
//  SlackowWall
//
//  Dynamically rendered eye projector overlay with configurable colors,
//  column count, and font. Replaces the static PNG overlays with a
//  customizable version.
//

import SwiftUI

struct DynamicEyeOverlay: View {
    let columnsPerSide: Int
    let color1: Color
    let color2: Color
    let textColor: Color
    let centerLineColor: Color
    let bandOpacity: Double
    let showDecadeMarkers: Bool

    private var totalColumns: Int { columnsPerSide * 2 }

    var body: some View {
        GeometryReader { geo in
            let colWidth = geo.size.width / CGFloat(totalColumns)
            let bandHeight = max(colWidth * 1.2, 20)
            let bandY = (geo.size.height - bandHeight) / 2

            ZStack(alignment: .topLeading) {
                // Colored columns with numbers
                columnBand(colWidth: colWidth, bandHeight: bandHeight, bandY: bandY, geoWidth: geo.size.width)

                // Center line
                Rectangle()
                    .fill(centerLineColor)
                    .frame(width: 1, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .allowsHitTesting(false)
    }

    private func columnBand(colWidth: CGFloat, bandHeight: CGFloat, bandY: CGFloat, geoWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<totalColumns, id: \.self) { i in
                columnCell(index: i, colWidth: colWidth, bandHeight: bandHeight)
            }
        }
        .frame(height: bandHeight)
        .offset(y: bandY)
    }

    private func columnCell(index: Int, colWidth: CGFloat, bandHeight: CGFloat) -> some View {
        let distFromCenter: Int
        if index < columnsPerSide {
            distFromCenter = columnsPerSide - index
        } else {
            distFromCenter = index - columnsPerSide + 1
        }

        let bgColor = (index % 2 == 0) ? color1 : color2
        let isDecadeBoundary = showDecadeMarkers && distFromCenter > 1 && distFromCenter % 10 == 0
        let label = showDecadeMarkers ? distFromCenter % 10 : distFromCenter

        let fontSize = min(colWidth * 0.8, bandHeight * 0.6)

        return ZStack {
            Rectangle()
                .fill(bgColor.opacity(bandOpacity))
            if isDecadeBoundary {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(centerLineColor)
                        .frame(width: 1)
                    Spacer()
                }
                let tens = distFromCenter / 10
                let ones = distFromCenter % 10
                let digitSize = fontSize * 0.7
                VStack(spacing: 0) {
                    Text("\(tens)")
                        .font(.system(size: digitSize, weight: .bold, design: .monospaced))
                        .foregroundStyle(textColor)
                    Text("\(ones)")
                        .font(.system(size: digitSize, weight: .bold, design: .monospaced))
                        .foregroundStyle(textColor)
                }
                .minimumScaleFactor(0.2)
                .lineLimit(1)
            } else {
                Text("\(label)")
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
            }
        }
        .frame(width: colWidth, height: bandHeight)
    }
}

#Preview {
    ZStack {
        Color.white
        DynamicEyeOverlay(
            columnsPerSide: 30,
            color1: Color(red: 1.0, green: 0.69, blue: 0.77),
            color2: Color(red: 0.68, green: 0.85, blue: 0.9),
            textColor: .black,
            centerLineColor: Color(white: 0.8),
            bandOpacity: 1.0,
            showDecadeMarkers: true
        )
    }
    .frame(width: 600, height: 400)
}
