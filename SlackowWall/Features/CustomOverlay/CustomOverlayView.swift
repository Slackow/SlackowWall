//
//  CustomOverlayView.swift
//  SlackowWall
//
//  Renders the custom overlay (e.g. a center crosshair). Stateless aside from
//  settings — the hosting window is centered on the Minecraft window by
//  CustomOverlayManager. CustomOverlayPreview reuses the same drawing for a
//  live settings preview.
//

import SwiftUI

struct CustomOverlayView: View {
    @ObservedObject private var manager = CustomOverlayManager.shared

    @AppSettings(\.utility)
    private var settings

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                if settings.customOverlayStyle == .customImage {
                    if let image = manager.image {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    Canvas { ctx, _ in
                        drawCustomOverlay(
                            ctx, style: settings.customOverlayStyle, center: center,
                            color: settings.customOverlayColor.color,
                            size: CGFloat(settings.customOverlaySize),
                            thickness: CGFloat(settings.customOverlayThickness),
                            gap: CGFloat(settings.customOverlayGap))
                    }
                }
            }
            .opacity(settings.customOverlayOpacity)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// Live preview of the overlay's current appearance, drawn on a fixed, neutral
/// backdrop so light-colored overlays stay visible while configuring.
struct CustomOverlayPreview: View {
    @AppSettings(\.utility)
    private var settings

    private var previewImage: NSImage? {
        guard settings.customOverlayStyle == .customImage else { return nil }
        return settings.customOverlayImage.flatMap { NSImage(contentsOf: $0) }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.12))
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)

            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let size = CGFloat(settings.customOverlaySize)
                if settings.customOverlayStyle == .customImage {
                    if let image = previewImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size, height: size)
                            .position(center)
                    }
                } else {
                    Canvas { ctx, _ in
                        drawCustomOverlay(
                            ctx, style: settings.customOverlayStyle, center: center,
                            color: settings.customOverlayColor.color,
                            size: size,
                            thickness: CGFloat(settings.customOverlayThickness),
                            gap: CGFloat(settings.customOverlayGap))
                    }
                }
            }
            .opacity(settings.customOverlayOpacity)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
}

/// Draws the built-in overlay shapes (cross / dot / circle / cross+dot) centered
/// at `center`. Shared by the live overlay window and the settings preview.
func drawCustomOverlay(
    _ ctx: GraphicsContext, style: CustomOverlayStyle, center: CGPoint,
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
