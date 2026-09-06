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

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 32, height: 12))
        shadow.fillColor = SKColor(white: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -22)
        shadow.zPosition = -2
        addChild(shadow)

        let padBase = SKShapeNode(rectOf: CGSize(width: 22, height: 10), cornerRadius: 3)
        padBase.fillColor = SKColor(hex: 0x164A5E)
        padBase.strokeColor = SKColor(hex: 0x00C2C7, alpha: 0.4)
        padBase.lineWidth = 1
        padBase.position = CGPoint(x: 0, y: -18)
        addChild(padBase)

        let post = SKShapeNode(rectOf: CGSize(width: 10, height: 48), cornerRadius: 4)
        post.fillColor = SKColor(hex: 0x1E5C75)
        post.strokeColor = SKColor(hex: 0x00D4D9, alpha: 0.6)
        post.lineWidth = 1.5
        post.glowWidth = 2
        post.position = CGPoint(x: 0, y: 3)
        addChild(post)
        
        let postHighlight = SKShapeNode(rectOf: CGSize(width: 3, height: 40), cornerRadius: 1.5)
        postHighlight.fillColor = SKColor(hex: 0x4AEEF5, alpha: 0.25)
        postHighlight.strokeColor = .clear
        postHighlight.position = CGPoint(x: -2, y: 3)
        addChild(postHighlight)

        let hoop = SKShapeNode(ellipseOf: CGSize(width: 28, height: 12))
        hoop.strokeColor = palette.cream
        hoop.fillColor = SKColor(hex: 0xFFFFFF, alpha: 0.12)
        hoop.lineWidth = 2.8
        hoop.glowWidth = 2
        hoop.position = CGPoint(x: 0, y: 26)
        addChild(hoop)
        ring = hoop

        for i in 0..<5 {
            let net = SKShapeNode(rectOf: CGSize(width: 1.2, height: 12), cornerRadius: 0.5)
            net.fillColor = SKColor(white: 1, alpha: 0.5)
            net.strokeColor = .clear
            net.position = CGPoint(x: CGFloat(i - 2) * 3.5, y: 18)
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
