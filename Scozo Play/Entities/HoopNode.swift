import SpriteKit

final class HoopNode: SKNode {
    let side: TeamSide
    private let config: GameConfig
    private var ring: SKShapeNode?

    init(side: TeamSide, config: GameConfig) {
        self.side = side
        self.config = config
        super.init()
        zPosition = ZLayer.players + 8
        rebuild()
    }

    required init?(coder: NSCoder) { nil }

    var goalPosition: CGPoint { position }
    var shotTarget: CGPoint { CGPoint(x: position.x, y: position.y + 18) }

    private func rebuild() {
        removeAllChildren()
        let palette = config.palette

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 10))
        shadow.fillColor = SKColor(white: 0, alpha: 0.28)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -18)
        shadow.zPosition = -2
        addChild(shadow)

        let post = SKShapeNode(rectOf: CGSize(width: 8, height: 42), cornerRadius: 3)
        post.fillColor = SKColor(hex: 0x2A6B8A)
        post.strokeColor = SKColor(hex: 0x8FD7E8)
        post.lineWidth = 1
        post.position = CGPoint(x: 0, y: 0)
        addChild(post)

        let pad = SKShapeNode(rectOf: CGSize(width: 16, height: 12), cornerRadius: 4)
        pad.fillColor = SKColor(hex: 0x1C4E68)
        pad.strokeColor = .clear
        pad.position = CGPoint(x: 0, y: -18)
        addChild(pad)

        let hoop = SKShapeNode(ellipseOf: CGSize(width: 26, height: 11))
        hoop.strokeColor = palette.cream
        hoop.fillColor = SKColor(hex: 0xFFFFFF, alpha: 0.1)
        hoop.lineWidth = 2.4
        hoop.glowWidth = 1
        hoop.position = CGPoint(x: 0, y: 20)
        addChild(hoop)
        ring = hoop

        for i in 0..<5 {
            let net = SKShapeNode(rectOf: CGSize(width: 1, height: 10), cornerRadius: 0.5)
            net.fillColor = SKColor(white: 1, alpha: 0.55)
            net.strokeColor = .clear
            net.position = CGPoint(x: CGFloat(i - 2) * 3.2, y: 14)
            addChild(net)
        }
    }

    func playScoreFlash() {
        let flash = SKShapeNode(circleOfRadius: 16)
        flash.fillColor = config.palette.success.withAlphaComponent(0.35)
        flash.strokeColor = config.palette.success
        flash.lineWidth = 2
        flash.zPosition = 4
        addChild(flash)
        flash.run(.sequence([
            .group([
                .scale(to: 2.2, duration: 0.28),
                .fadeOut(withDuration: 0.28)
            ]),
            .removeFromParent()
        ]))
        ring?.run(.sequence([
            .scale(to: 1.18, duration: 0.08),
            .scale(to: 1.0, duration: 0.12)
        ]))
    }
}
