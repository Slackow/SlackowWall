//
//  CrosshairOverlayView.swift
//  SlackowWall
//
//  Renders the center crosshair. Stateless aside from settings — the hosting
//  window is centered on the Minecraft window by CrosshairManager.
//

import SwiftUI

struct CrosshairOverlayView: View {
    @ObservedObject private var manager = CrosshairManager.shared

    @AppSettings(\.utility)
    private var settings

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let color = settings.eyeCrosshairColor.color
            let size = CGFloat(settings.eyeCrosshairSize)
            let thickness = CGFloat(settings.eyeCrosshairThickness)
            let gap = CGFloat(settings.eyeCrosshairGap)

            ZStack {
                if settings.eyeCrosshairStyle == .customImage {
                    if let image = manager.image {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    Canvas { ctx, _ in
                        draw(
                            ctx, style: settings.eyeCrosshairStyle, center: center,
                            color: color, size: size, thickness: thickness, gap: gap)
                    }
                }
            }
            .opacity(settings.eyeCrosshairOpacity)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func draw(
        _ ctx: GraphicsContext, style: CrosshairStyle, center: CGPoint,
        color: Color, size: CGFloat, thickness: CGFloat, gap: CGFloat
    ) {
        let half = size / 2
        let shading = GraphicsContext.Shading.color(color)

        if style == .cross || style == .crossDot {
            var arms = Path()
            // horizontal
            arms.addRect(
                CGRect(
                    x: center.x - half, y: center.y - thickness / 2,
                    width: half - gap, height: thickness))
            arms.addRect(
                CGRect(
                    x: center.x + gap, y: center.y - thickness / 2,
                    width: half - gap, height: thickness))
            // vertical
            arms.addRect(
                CGRect(
                    x: center.x - thickness / 2, y: center.y - half,
                    width: thickness, height: half - gap))
            arms.addRect(
                CGRect(
                    x: center.x - thickness / 2, y: center.y + gap,
                    width: thickness, height: half - gap))
            ctx.fill(arms, with: shading)
        }

        if style == .circle {
            let rect = CGRect(
                x: center.x - half, y: center.y - half, width: size, height: size)
            ctx.stroke(Path(ellipseIn: rect), with: shading, lineWidth: thickness)
        }

        if style == .dot || style == .crossDot {
            let dotRadius = max(thickness, size * 0.08)
            let rect = CGRect(
                x: center.x - dotRadius, y: center.y - dotRadius,
                width: dotRadius * 2, height: dotRadius * 2)
            ctx.fill(Path(ellipseIn: rect), with: shading)
        }
    }
}
