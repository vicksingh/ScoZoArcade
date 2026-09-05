import Foundation
import SpriteKit
import UIKit

enum ProceduralArt {
    static func woodTexture() -> SKTexture {
        let size = CGSize(width: 256, height: 512)
        let image = UIGraphicsImageRenderer(size: size).image { renderer in
            let ctx = renderer.cgContext
            SKColor(hex: 0xC9A06A).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            for i in 0..<18 {
                let t = CGFloat(i) / 18
                let x = t * size.width + CGFloat((i * 17) % 7) - 3
                let color = i.isMultiple(of: 2)
                    ? SKColor(hex: 0xE4C899, alpha: 0.35)
                    : SKColor(hex: 0x8C6840, alpha: 0.22)
                color.setStroke()
                ctx.setLineWidth(CGFloat(7 + i % 4))
                ctx.move(to: CGPoint(x: x, y: 0))
                ctx.addCurve(
                    to: CGPoint(x: x + 6, y: size.height),
                    control1: CGPoint(x: x + 10, y: size.height * 0.33),
                    control2: CGPoint(x: x - 8, y: size.height * 0.66)
                )
                ctx.strokePath()
            }
            for _ in 0..<240 {
                let px = CGFloat.random(in: 0...size.width)
                let py = CGFloat.random(in: 0...size.height)
                SKColor(hex: 0x6F4B2A, alpha: CGFloat.random(in: 0.04...0.12)).setFill()
                ctx.fill(CGRect(x: px, y: py, width: 1.4, height: 2.2))
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static func ballTexture() -> SKTexture {
        let side: CGFloat = 64
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { renderer in
            let ctx = renderer.cgContext
            let rect = CGRect(x: 4, y: 4, width: 56, height: 56)
            ctx.addEllipse(in: rect)
            ctx.clip()
            let colors = [
                SKColor(hex: 0xFFFFFF).cgColor,
                SKColor(hex: 0xF3F1EC).cgColor,
                SKColor(hex: 0xC9B8A0).cgColor
            ]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 0.45, 1]
            ) {
                ctx.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: 24, y: 22),
                    startRadius: 2,
                    endCenter: CGPoint(x: 32, y: 32),
                    endRadius: 30,
                    options: [.drawsAfterEndLocation]
                )
            }
            ctx.resetClip()
            SKColor(hex: 0xC45A3A, alpha: 0.85).setStroke()
            ctx.setLineWidth(1.6)
            ctx.addEllipse(in: rect.insetBy(dx: 8, dy: 18))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: 32, y: 8))
            ctx.addLine(to: CGPoint(x: 32, y: 56))
            ctx.strokePath()
        }
        return SKTexture(image: image)
    }

    static func vignetteTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 128)
        let image = UIGraphicsImageRenderer(size: size).image { renderer in
            let ctx = renderer.cgContext
            let colors = [
                SKColor(white: 0, alpha: 0).cgColor,
                SKColor(white: 0, alpha: 0.55).cgColor
            ]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.42, 1]
            ) {
                ctx.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: 32, y: 70),
                    startRadius: 8,
                    endCenter: CGPoint(x: 32, y: 64),
                    endRadius: 48,
                    options: [.drawsAfterEndLocation]
                )
            }
        }
        return SKTexture(image: image)
    }
}
