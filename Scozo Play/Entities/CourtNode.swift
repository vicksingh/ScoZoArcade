import Foundation
import SpriteKit

/// Decorative isometric court. Gameplay queries use `geometry`, not these paths.
final class CourtNode: SKNode {
    let geometry: CourtGeometry
    private let config: GameConfig
    private(set) var boardRect: CGRect = .zero
    private let woodTexture = ProceduralArt.woodTexture()
    private let vignetteTexture = ProceduralArt.vignetteTexture()

    init(geometry: CourtGeometry, config: GameConfig) {
        self.geometry = geometry
        self.config = config
        super.init()
        zPosition = ZLayer.court
    }

    required init?(coder: NSCoder) { nil }

    func layout(in sceneSize: CGSize, safeTop: CGFloat, safeBottom: CGFloat) {
        removeAllChildren()
        let palette = config.palette
        let topReserve = max(safeTop + 92, 126)
        let bottomReserve = max(safeBottom + 228, 240)
        let available = CGRect(
            x: 10,
            y: bottomReserve,
            width: sceneSize.width - 20,
            height: sceneSize.height - topReserve - bottomReserve
        )
        let boardWidth = min(available.width, available.height * 0.88)
        let boardHeight = min(available.height, boardWidth * 1.16)
        boardRect = CGRect(
            x: available.midX - boardWidth * 0.5,
            y: available.minY + (available.height - boardHeight) * 0.18,
            width: boardWidth,
            height: boardHeight
        )

        drawArena(sceneSize: sceneSize, palette: palette)
        drawCrowd(sceneSize: sceneSize)
        drawSurrounds(palette: palette)
        drawBoard()
        drawFarWash(palette: palette)
        drawLines(palette: palette)
        drawVignette(sceneSize: sceneSize)
    }

    func displayPoint(fromCourt point: CGPoint) -> CGPoint {
        geometry.displayPoint(fromCourt: point, in: boardRect)
    }

    func courtPoint(fromDisplay point: CGPoint) -> CGPoint {
        geometry.courtPoint(fromDisplay: point, in: boardRect)
    }

    private func project(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        displayPoint(fromCourt: CGPoint(x: x, y: y))
    }

    private func drawArena(sceneSize: CGSize, palette: GamePalette) {
        let bg = SKSpriteNode(color: palette.arenaDeep, size: sceneSize)
        bg.anchorPoint = .zero
        bg.position = .zero
        bg.zPosition = ZLayer.arena
        addChild(bg)

        let wash = SKSpriteNode(color: SKColor(hex: 0x0B2A38), size: CGSize(width: sceneSize.width, height: sceneSize.height * 0.55))
        wash.anchorPoint = CGPoint(x: 0.5, y: 1)
        wash.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height)
        wash.alpha = 0.85
        wash.zPosition = ZLayer.arena + 0.1
        addChild(wash)
    }

    private func drawCrowd(sceneSize: CGSize) {
        let band = SKNode()
        band.zPosition = ZLayer.arena + 0.3
        band.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.78)
        for i in 0..<22 {
            let blob = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 18...34), height: CGFloat.random(in: 22...40)))
            blob.fillColor = SKColor(hex: 0x08141C, alpha: CGFloat.random(in: 0.45...0.8))
            blob.strokeColor = .clear
            blob.position = CGPoint(x: CGFloat(i - 11) * 18 + CGFloat.random(in: -6...6), y: CGFloat.random(in: -10...28))
            band.addChild(blob)
        }
        band.alpha = 0.7
        addChild(band)
    }

    private func drawSurrounds(palette: GamePalette) {
        let wall = projectedPolygon([
            CGPoint(x: -22, y: -22),
            CGPoint(x: geometry.size.width + 22, y: -22),
            CGPoint(x: geometry.size.width + 10, y: geometry.size.height + 22),
            CGPoint(x: -10, y: geometry.size.height + 22)
        ])
        wall.fillColor = SKColor(hex: 0x0A3544)
        wall.strokeColor = SKColor(hex: 0x00C2C7, alpha: 0.28)
        wall.lineWidth = 2
        wall.zPosition = ZLayer.surround
        addChild(wall)

        for y in [0.18, 0.50, 0.82] {
            placeWordmark(atCourt: CGPoint(x: -12, y: geometry.size.height * y), rotated: .pi / 2)
            placeWordmark(atCourt: CGPoint(x: geometry.size.width + 12, y: geometry.size.height * y), rotated: -.pi / 2)
        }
        _ = palette
    }

    private func placeWordmark(atCourt point: CGPoint, rotated: CGFloat) {
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        label.text = "SCOZO"
        label.fontSize = 20
        label.fontColor = SKColor(hex: 0x8FD7DC, alpha: 0.28)
        label.verticalAlignmentMode = .center
        label.position = displayPoint(fromCourt: point)
        label.zRotation = rotated
        label.zPosition = ZLayer.surround + 0.4
        addChild(label)
    }

    private func drawBoard() {
        let crop = SKCropNode()
        crop.zPosition = ZLayer.court
        let mask = projectedPolygon([
            .zero,
            CGPoint(x: geometry.size.width, y: 0),
            CGPoint(x: geometry.size.width, y: geometry.size.height),
            CGPoint(x: 0, y: geometry.size.height)
        ])
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask

        let wood = SKSpriteNode(texture: woodTexture, size: CGSize(width: boardRect.width * 1.15, height: boardRect.height * 1.15))
        wood.position = CGPoint(x: boardRect.midX, y: boardRect.midY)
        wood.zRotation = -0.015
        crop.addChild(wood)
        addChild(crop)

        let edge = projectedPolygon([
            .zero,
            CGPoint(x: geometry.size.width, y: 0),
            CGPoint(x: geometry.size.width, y: geometry.size.height),
            CGPoint(x: 0, y: geometry.size.height)
        ])
        edge.fillColor = .clear
        edge.strokeColor = SKColor(hex: 0x6A4A28, alpha: 0.85)
        edge.lineWidth = 3
        edge.zPosition = ZLayer.court + 0.4
        addChild(edge)
    }

    private func drawFarWash(palette: GamePalette) {
        let wash = projectedPolygon([
            CGPoint(x: 0, y: geometry.size.height * 0.55),
            CGPoint(x: geometry.size.width, y: geometry.size.height * 0.55),
            CGPoint(x: geometry.size.width, y: geometry.size.height),
            CGPoint(x: 0, y: geometry.size.height)
        ])
        wash.fillColor = palette.arenaDeep.withAlphaComponent(0.18)
        wash.strokeColor = .clear
        wash.zPosition = ZLayer.court + 0.35
        addChild(wash)
    }

    private func drawVignette(sceneSize: CGSize) {
        let vignette = SKSpriteNode(texture: vignetteTexture, size: sceneSize)
        vignette.anchorPoint = .zero
        vignette.position = .zero
        vignette.zPosition = ZLayer.effects - 1
        vignette.alpha = 0.9
        addChild(vignette)
    }

    private func drawLines(palette: GamePalette) {
        let cream = palette.cream
        addPolyLine([
            .zero,
            CGPoint(x: geometry.size.width, y: 0),
            CGPoint(x: geometry.size.width, y: geometry.size.height),
            CGPoint(x: 0, y: geometry.size.height)
        ], color: cream, width: 2.4, closed: true)

        for third in [1, 2] {
            let y = geometry.thirdHeight * CGFloat(third)
            addPolyLine([
                CGPoint(x: 0, y: y),
                CGPoint(x: geometry.size.width, y: y)
            ], color: cream, width: 1.8, closed: false)
        }

        addCircle(center: geometry.centreMark, radius: 38, color: cream, width: 2)
        addCircle(center: geometry.shootingCircleCenter(for: .home), radius: geometry.shootingCircleRadius, color: cream, width: 2.2)
        addCircle(center: geometry.shootingCircleCenter(for: .away), radius: geometry.shootingCircleRadius, color: cream, width: 2.2)

        let mid = SKShapeNode(circleOfRadius: 3)
        mid.fillColor = cream
        mid.strokeColor = .clear
        mid.position = displayPoint(fromCourt: geometry.centreMark)
        mid.zPosition = ZLayer.lines
        addChild(mid)
    }

    private func addCircle(center: CGPoint, radius: CGFloat, color: SKColor, width: CGFloat) {
        let steps = 32
        var points: [CGPoint] = []
        for i in 0...steps {
            let a = CGFloat(i) / CGFloat(steps) * .pi * 2
            points.append(CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius))
        }
        addPolyLine(points, color: color, width: width, closed: true)
    }

    private func addPolyLine(_ points: [CGPoint], color: SKColor, width: CGFloat, closed: Bool) {
        let path = CGMutablePath()
        guard let first = points.first else { return }
        path.move(to: displayPoint(fromCourt: first))
        for point in points.dropFirst() {
            path.addLine(to: displayPoint(fromCourt: point))
        }
        if closed { path.closeSubpath() }
        let node = SKShapeNode(path: path)
        node.strokeColor = color
        node.fillColor = .clear
        node.lineWidth = width
        node.lineCap = .round
        node.glowWidth = 0.4
        node.zPosition = ZLayer.lines
        addChild(node)
    }

    private func projectedPolygon(_ points: [CGPoint]) -> SKShapeNode {
        let path = CGMutablePath()
        guard let first = points.first else { return SKShapeNode() }
        path.move(to: displayPoint(fromCourt: first))
        for point in points.dropFirst() {
            path.addLine(to: displayPoint(fromCourt: point))
        }
        path.closeSubpath()
        return SKShapeNode(path: path)
    }
}
