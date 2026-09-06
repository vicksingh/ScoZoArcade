import SpriteKit

/// Ball node for Shootout mode.
/// Uses 2D art pack texture when available, otherwise falls back to procedural texture.
final class ShootoutBallNode: SKNode {
    private let config: GameConfig
    private let ball: SKSpriteNode
    private let rim: SKShapeNode
    private let shadow: SKShapeNode
    private let trail: SKShapeNode
    private let useTexture: Bool
    
    init(config: GameConfig) {
        self.config = config
        self.useTexture = ShootoutAssets.ballTexture() != nil
        
        if let texture = ShootoutAssets.ballTexture() {
            self.ball = SKSpriteNode(texture: texture, size: CGSize(width: 16, height: 16))
        } else {
            self.ball = SKSpriteNode(texture: ProceduralArt.ballTexture(), size: CGSize(width: 16, height: 16))
        }
        
        self.rim = SKShapeNode(circleOfRadius: 8.2)
        self.shadow = SKShapeNode(ellipseOf: CGSize(width: 16, height: 7))
        self.trail = SKShapeNode(circleOfRadius: 6)
        super.init()
        zPosition = ZLayer.players + 14
        
        shadow.fillColor = SKColor(white: 0, alpha: 0.32)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -11)
        addChild(shadow)
        
        trail.fillColor = SKColor(white: 1, alpha: 0.2)
        trail.strokeColor = .clear
        trail.alpha = 0
        addChild(trail)
        
        addChild(ball)
        
        if !useTexture {
            rim.fillColor = .clear
            rim.strokeColor = SKColor(white: 1, alpha: 0.28)
            rim.lineWidth = 0.8
            addChild(rim)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    func sync(runtime: BallRuntime, display: CGPoint, scale: CGFloat, airborne: Bool) {
        position = display
        setScale(max(1.05, scale) * (airborne ? 1.08 : 1))
        zPosition = ZLayer.players + 16 + (airborne ? 6 : 0)
        trail.alpha = airborne ? 0.5 : 0
        trail.position = CGPoint(x: -5, y: -4)
        shadow.alpha = airborne ? 0.14 : 0.32
        shadow.xScale = airborne ? 0.65 : 1
    }
}
