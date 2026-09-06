import Foundation
import SpriteKit

/// Player node for Shootout mode.
/// Uses 2D art pack textures when available, otherwise falls back to shape-based placeholders.
final class ShootoutPlayerNode: SKNode {
    let athlete: Athlete
    private let config: GameConfig
    private let role: ShootoutAssets.PlayerRole
    private let textures: [ShootoutAssets.PlayerPose: SKTexture]
    private let useTextures: Bool
    
    private var currentPose: ShootoutAssets.PlayerPose = .idle
    private let sprite: SKSpriteNode?
    private let bodyRoot: SKNode?
    private let shadow: SKShapeNode
    private let selection: SKNode
    private let possession: SKShapeNode
    private let heldWarning: SKShapeNode
    private let facingMark: SKShapeNode
    private let label: SKLabelNode
    
    init(athlete: Athlete, config: GameConfig) {
        self.athlete = athlete
        self.config = config
        self.role = ShootoutAssets.PlayerRole(rawValue: athlete.id.role.rawValue) ?? .gs
        self.textures = ShootoutAssets.playerTextures(role: role)
        self.useTextures = !textures.isEmpty
        
        self.shadow = SKShapeNode(ellipseOf: CGSize(width: 30, height: 11))
        self.possession = SKShapeNode(ellipseOf: CGSize(width: 32, height: 12))
        self.heldWarning = SKShapeNode(ellipseOf: CGSize(width: 42, height: 16))
        self.facingMark = SKShapeNode()
        self.label = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        
        if useTextures {
            self.sprite = SKSpriteNode(texture: textures[.idle], size: CGSize(width: 48, height: 64))
            self.bodyRoot = nil
            self.selection = ShootoutPlayerNode.loadSelectionNode(config: config)
        } else {
            self.sprite = nil
            self.bodyRoot = SKNode()
            self.selection = SKShapeNode(ellipseOf: CGSize(width: 38, height: 14))
        }
        
        super.init()
        assemble()
    }
    
    required init?(coder: NSCoder) { nil }
    
    private static func loadSelectionNode(config: GameConfig) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -20)
        
        let outerGlow = SKShapeNode(ellipseOf: CGSize(width: 46, height: 17))
        outerGlow.strokeColor = config.palette.teal.withAlphaComponent(0.35)
        outerGlow.fillColor = .clear
        outerGlow.lineWidth = 6
        outerGlow.glowWidth = 12
        outerGlow.zPosition = -1
        container.addChild(outerGlow)
        
        let ring = SKShapeNode(ellipseOf: CGSize(width: 40, height: 15))
        ring.strokeColor = config.palette.teal
        ring.fillColor = config.palette.teal.withAlphaComponent(0.18)
        ring.lineWidth = 2.5
        ring.glowWidth = 4
        container.addChild(ring)
        
        let highlight = SKShapeNode(ellipseOf: CGSize(width: 32, height: 11))
        highlight.strokeColor = SKColor(white: 1, alpha: 0.45)
        highlight.fillColor = .clear
        highlight.lineWidth = 1
        highlight.position = CGPoint(x: 0, y: 1)
        container.addChild(highlight)
        
        return container
    }
    
    private func assemble() {
        let kit = config.palette.primary(for: athlete.id.side)
        let kitDark = config.palette.secondary(for: athlete.id.side)
        
        shadow.fillColor = SKColor(white: 0, alpha: 0.38)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 1, y: -20)
        shadow.zPosition = -2
        addChild(shadow)
        
        selection.isHidden = true
        addChild(selection)
        
        possession.strokeColor = SKColor(white: 1, alpha: 0.55)
        possession.fillColor = .clear
        possession.lineWidth = 1.2
        possession.position = CGPoint(x: 0, y: -20)
        possession.isHidden = true
        addChild(possession)
        
        heldWarning.strokeColor = config.palette.warning
        heldWarning.fillColor = .clear
        heldWarning.lineWidth = 2.2
        heldWarning.glowWidth = 3
        heldWarning.position = CGPoint(x: 0, y: -20)
        heldWarning.isHidden = true
        addChild(heldWarning)
        
        let chevron = CGMutablePath()
        chevron.move(to: CGPoint(x: 0, y: 7))
        chevron.addLine(to: CGPoint(x: 4, y: 0))
        chevron.addLine(to: CGPoint(x: -4, y: 0))
        chevron.closeSubpath()
        facingMark.path = chevron
        facingMark.fillColor = kit.withAlphaComponent(0.7)
        facingMark.strokeColor = .clear
        facingMark.position = CGPoint(x: 0, y: -26)
        facingMark.zPosition = -1
        addChild(facingMark)
        
        if useTextures, let sprite {
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.25)
            addChild(sprite)
        } else if let bodyRoot {
            addChild(bodyRoot)
            bodyRoot.position = CGPoint(x: 0, y: -2)
            assembleShapeBody(kit: kit, kitDark: kitDark)
        }
        
        label.text = athlete.id.role.displayLabel
        label.fontSize = 10
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: useTextures ? -8 : 5)
        label.fontName = "AvenirNextCondensed-Heavy"
        if useTextures {
            addChild(label)
        } else {
            bodyRoot?.addChild(label)
        }
    }
    
    private func assembleShapeBody(kit: SKColor, kitDark: SKColor) {
        guard let bodyRoot else { return }
        
        let leftLeg = SKShapeNode(rectOf: CGSize(width: 5.5, height: 13), cornerRadius: 2)
        leftLeg.fillColor = kitDark
        leftLeg.strokeColor = .clear
        leftLeg.position = CGPoint(x: -4.2, y: -14)
        bodyRoot.addChild(leftLeg)
        
        let rightLeg = SKShapeNode(rectOf: CGSize(width: 5.5, height: 13), cornerRadius: 2)
        rightLeg.fillColor = kitDark
        rightLeg.strokeColor = .clear
        rightLeg.position = CGPoint(x: 4.2, y: -14)
        bodyRoot.addChild(rightLeg)
        
        let shorts = SKShapeNode(rectOf: CGSize(width: 16, height: 8), cornerRadius: 3)
        shorts.fillColor = kitDark
        shorts.strokeColor = .clear
        shorts.position = CGPoint(x: 0, y: -8)
        bodyRoot.addChild(shorts)
        
        let torso = SKShapeNode(rectOf: CGSize(width: 18, height: 20), cornerRadius: 6)
        torso.fillColor = kit
        torso.strokeColor = SKColor(white: 1, alpha: 0.22)
        torso.lineWidth = 0.8
        torso.position = CGPoint(x: 0, y: 4)
        bodyRoot.addChild(torso)
        
        let gloss = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 3)
        gloss.fillColor = SKColor(white: 1, alpha: 0.18)
        gloss.strokeColor = .clear
        gloss.position = CGPoint(x: -4, y: 6)
        torso.addChild(gloss)
        
        let leftArm = SKShapeNode(rectOf: CGSize(width: 4.5, height: 13), cornerRadius: 2)
        leftArm.fillColor = kit
        leftArm.strokeColor = .clear
        leftArm.position = CGPoint(x: -12, y: 2)
        leftArm.zRotation = 0.25
        bodyRoot.addChild(leftArm)
        
        let rightArm = SKShapeNode(rectOf: CGSize(width: 4.5, height: 13), cornerRadius: 2)
        rightArm.fillColor = kit
        rightArm.strokeColor = .clear
        rightArm.position = CGPoint(x: 12, y: 2)
        rightArm.zRotation = -0.25
        bodyRoot.addChild(rightArm)
        
        let head = SKShapeNode(circleOfRadius: 6.4)
        head.fillColor = SKColor(hex: 0xE8B894)
        head.strokeColor = kitDark.withAlphaComponent(0.5)
        head.lineWidth = 0.6
        head.position = CGPoint(x: 0, y: 20)
        bodyRoot.addChild(head)
        
        let hair = SKShapeNode(ellipseOf: CGSize(width: 14, height: 8))
        hair.fillColor = SKColor(hex: 0x2B1A14)
        hair.strokeColor = .clear
        hair.position = CGPoint(x: 1, y: 24)
        bodyRoot.addChild(hair)
    }
    
    func sync(from athlete: Athlete, display: CGPoint, scale: CGFloat, heldRemaining: TimeInterval?) {
        position = display
        setScale(scale)
        zPosition = ZLayer.players + (1.2 - scale) * 14
        setSelected(athlete.isSelected)
        setHasBall(athlete.hasBall)
        setFacing(athlete.facing)
        updatePose(for: athlete)
        
        if let heldRemaining, athlete.hasBall, heldRemaining <= 1.05 {
            heldWarning.isHidden = false
            heldWarning.alpha = 0.55 + 0.45 * CGFloat(1 - heldRemaining)
            let pulse = 1 + CGFloat(1 - heldRemaining) * 0.18
            heldWarning.xScale = pulse
            heldWarning.yScale = pulse
        } else {
            heldWarning.isHidden = true
        }
        shadow.xScale = 1.05 + (1.2 - scale) * 0.4
        shadow.alpha = 0.28 + (1.2 - scale) * 0.2
    }
    
    private func updatePose(for athlete: Athlete) {
        guard useTextures, let sprite else { return }
        
        let newPose: ShootoutAssets.PlayerPose
        let isMoving = hypot(athlete.velocity.dx, athlete.velocity.dy) > 10
        
        if athlete.hasBall {
            newPose = .idle
        } else if isMoving {
            newPose = .shuffle
        } else {
            newPose = .idle
        }
        
        if newPose != currentPose, let texture = textures[newPose] {
            currentPose = newPose
            sprite.texture = texture
        }
    }
    
    func setPose(_ pose: ShootoutAssets.PlayerPose) {
        guard useTextures, let sprite, let texture = textures[pose] else { return }
        currentPose = pose
        sprite.texture = texture
    }
    
    func setHasBall(_ value: Bool) {
        athlete.hasBall = value
        possession.isHidden = !value
    }
    
    func setSelected(_ value: Bool) {
        athlete.isSelected = value
        selection.isHidden = !value
    }
    
    func setFacing(_ radians: CGFloat) {
        athlete.facing = radians
        facingMark.zRotation = radians - .pi / 2
        if let bodyRoot, abs(cos(radians)) > 0.18 {
            bodyRoot.xScale = cos(radians) < 0 ? -1 : 1
            label.xScale = bodyRoot.xScale
        }
        if useTextures, let sprite {
            sprite.xScale = cos(radians) < 0 ? -1 : 1
        }
    }
    
    func pulse() {
        run(.sequence([
            .scale(to: xScale * 1.1, duration: 0.08),
            .scale(to: xScale, duration: 0.1)
        ]))
    }
}
