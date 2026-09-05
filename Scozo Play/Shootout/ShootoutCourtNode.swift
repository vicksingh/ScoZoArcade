import Foundation
import SpriteKit

final class ShootoutCourtNode: SKNode {
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
        let boardHeight = min(available.height, boardWidth * 0.92)
        
        boardRect = CGRect(
            x: available.midX - boardWidth * 0.5,
            y: available.minY + (available.height - boardHeight) * 0.2,
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
        band.position = CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.82)
        for i in 0..<18 {
            let blob = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 18...34), height: CGFloat.random(in: 22...40)))
            blob.fillColor = SKColor(hex: 0x08141C, alpha: CGFloat.random(in: 0.45...0.8))
            blob.strokeColor = .clear
            blob.position = CGPoint(x: CGFloat(i - 9) * 20 + CGFloat.random(in: -6...6), y: CGFloat.random(in: -10...28))
            band.addChild(blob)
        }
        band.alpha = 0.7
        addChild(band)
    }
    
    private func drawSurrounds(palette: GamePalette) {
        let circleCenter = geometry.shootingCircleCenter(for: .home)
        let radius = geometry.shootingCircleRadius
        let apron: CGFloat = 50
        
        let minY = circleCenter.y - radius - apron
        let maxY = geometry.size.height + 20
        
        let wall = projectedPolygon([
            CGPoint(x: -22, y: max(0, minY - 20)),
            CGPoint(x: geometry.size.width + 22, y: max(0, minY - 20)),
            CGPoint(x: geometry.size.width + 10, y: maxY),
            CGPoint(x: -10, y: maxY)
        ])
        wall.fillColor = SKColor(hex: 0x0A3544)
        wall.strokeColor = SKColor(hex: 0x00C2C7, alpha: 0.28)
        wall.lineWidth = 2
        wall.zPosition = ZLayer.surround
        addChild(wall)
        
        placeWordmark(atCourt: CGPoint(x: -12, y: circleCenter.y), rotated: .pi / 2)
        placeWordmark(atCourt: CGPoint(x: geometry.size.width + 12, y: circleCenter.y), rotated: -.pi / 2)
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        titleLabel.text = "SHOOTOUT"
        titleLabel.fontSize = 18
        titleLabel.fontColor = SKColor(hex: 0x8FD7DC, alpha: 0.45)
        titleLabel.position = displayPoint(fromCourt: CGPoint(x: geometry.midX, y: geometry.size.height + 8))
        titleLabel.zPosition = ZLayer.surround + 0.5
        addChild(titleLabel)
        _ = palette
    }
    
    private func placeWordmark(atCourt point: CGPoint, rotated: CGFloat) {
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        label.text = "SCOZO"
        label.fontSize = 18
        label.fontColor = SKColor(hex: 0x8FD7DC, alpha: 0.28)
        label.verticalAlignmentMode = .center
        label.position = displayPoint(fromCourt: point)
        label.zRotation = rotated
        label.zPosition = ZLayer.surround + 0.4
        addChild(label)
    }
    
    private func drawBoard() {
        let circleCenter = geometry.shootingCircleCenter(for: .home)
        let radius = geometry.shootingCircleRadius
        let apron: CGFloat = 50
        
        let minY = max(0, circleCenter.y - radius - apron)
        
        let crop = SKCropNode()
        crop.zPosition = ZLayer.court
        let mask = projectedPolygon([
            CGPoint(x: 0, y: minY),
            CGPoint(x: geometry.size.width, y: minY),
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
            CGPoint(x: 0, y: minY),
            CGPoint(x: geometry.size.width, y: minY),
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
        let circleCenter = geometry.shootingCircleCenter(for: .home)
        let wash = projectedPolygon([
            CGPoint(x: 0, y: circleCenter.y + 30),
            CGPoint(x: geometry.size.width, y: circleCenter.y + 30),
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
        let circleCenter = geometry.shootingCircleCenter(for: .home)
        
        addCircle(center: circleCenter, radius: geometry.shootingCircleRadius, color: cream, width: 2.4)
        
        let apron: CGFloat = 50
        let minY = max(0, circleCenter.y - geometry.shootingCircleRadius - apron)
        addPolyLine([
            CGPoint(x: 0, y: minY),
            CGPoint(x: geometry.size.width, y: minY),
            CGPoint(x: geometry.size.width, y: geometry.size.height),
            CGPoint(x: 0, y: geometry.size.height)
        ], color: cream, width: 2.2, closed: true)
        
        addPolyLine([
            CGPoint(x: 0, y: circleCenter.y - geometry.shootingCircleRadius - 8),
            CGPoint(x: geometry.size.width, y: circleCenter.y - geometry.shootingCircleRadius - 8)
        ], color: cream.withAlphaComponent(0.5), width: 1.4, closed: false)
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
