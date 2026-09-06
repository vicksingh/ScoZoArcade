import SpriteKit
import UIKit

final class VirtualControlsNode: SKNode {
    private let config: GameConfig
    private weak var input: InputSystem?
    private let pad = SKNode()
    private let padBase = SKShapeNode(circleOfRadius: 58)
    private let padKnob = SKShapeNode(circleOfRadius: 16)
    private let shootButton = SKShapeNode(rectOf: CGSize(width: 56, height: 56), cornerRadius: 14)
    private let passButton = SKShapeNode(rectOf: CGSize(width: 56, height: 56), cornerRadius: 14)
    private let switchButton = SKShapeNode(rectOf: CGSize(width: 56, height: 56), cornerRadius: 14)
    private var activePad: UITouch?
    private var shootLegal = true
    private var passLegal = false
    private let buttonSize: CGFloat = 56
    private let buttonGap: CGFloat = 8

    init(config: GameConfig, input: InputSystem) {
        self.config = config
        self.input = input
        super.init()
        zPosition = ZLayer.controls
        isUserInteractionEnabled = true
        assemble()
    }

    required init?(coder: NSCoder) { nil }

    func layout(in size: CGSize, safeBottom: CGFloat) {
        let inset: CGFloat = 18
        let stackX = size.width - inset - buttonSize * 0.5
        let switchY = safeBottom + 18 + buttonSize * 0.5
        switchButton.position = CGPoint(x: stackX, y: switchY)
        passButton.position = CGPoint(x: stackX, y: switchY + buttonSize + buttonGap)
        shootButton.position = CGPoint(x: stackX, y: switchY + (buttonSize + buttonGap) * 2)
        pad.position = CGPoint(x: 72, y: switchY + buttonSize + buttonGap)
    }

    func setShootLegal(_ legal: Bool) {
        shootLegal = legal
        shootButton.alpha = legal ? 1 : 0.38
        shootButton.strokeColor = legal ? config.palette.teal : SKColor(white: 1, alpha: 0.22)
        shootButton.glowWidth = legal ? 4 : 0
    }

    func setPassLegal(_ legal: Bool) {
        passLegal = legal
        passButton.alpha = legal ? 1 : 0.38
        passButton.strokeColor = legal ? config.palette.teal : SKColor(white: 1, alpha: 0.22)
        passButton.glowWidth = legal ? 4 : 0
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handle(touch, ended: false, cancelled: false) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handle(touch, ended: false, cancelled: false) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handle(touch, ended: true, cancelled: false) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handle(touch, ended: true, cancelled: true) }
    }

    private func handle(_ touch: UITouch, ended: Bool, cancelled: Bool) {
        let point = touch.location(in: self)
        if activePad == nil && !ended && inPad(point) {
            activePad = touch
        }
        if touch == activePad || (activePad == nil && inPad(point)) {
            if ended || cancelled {
                activePad = nil
                input?.clearMove()
                padKnob.position = .zero
            } else {
                let local = CGPoint(x: point.x - pad.position.x, y: point.y - pad.position.y)
                let len = hypot(local.x, local.y)
                let clamped = min(len, 44)
                let nx = len > 0 ? local.x / len : 0
                let ny = len > 0 ? local.y / len : 0
                padKnob.position = CGPoint(x: nx * clamped, y: ny * clamped)
                input?.setMove(CGVector(dx: nx * (clamped / 44), dy: ny * (clamped / 44)), deadZone: config.inputDeadZone)
            }
            return
        }

        if inButton(point, node: shootButton) {
            if !ended {
                if shootLegal {
                    press(shootButton)
                    input?.pressShoot()
                } else {
                    rejectFlash(shootButton)
                    input?.pressShoot()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                release(shootButton)
                input?.releaseShoot()
            }
            return
        }
        if ended, inButton(point, node: passButton) {
            if passLegal {
                flash(passButton)
            } else {
                rejectFlash(passButton)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            input?.requestPass()
            return
        }
        if ended, inButton(point, node: switchButton) {
            flash(switchButton)
            input?.requestSwitch()
        }
    }

    override func contains(_ p: CGPoint) -> Bool {
        containsControl(p)
    }

    func containsControl(_ point: CGPoint) -> Bool {
        inPad(point)
            || inButton(point, node: shootButton)
            || inButton(point, node: passButton)
            || inButton(point, node: switchButton)
    }

    private func inPad(_ point: CGPoint) -> Bool {
        hypot(point.x - pad.position.x, point.y - pad.position.y) < 78
    }

    private func inButton(_ point: CGPoint, node: SKNode) -> Bool {
        let extra: CGFloat = 10
        let rect = CGRect(
            x: node.position.x - buttonSize * 0.5 - extra,
            y: node.position.y - buttonSize * 0.5 - extra,
            width: buttonSize + extra * 2,
            height: buttonSize + extra * 2
        )
        return rect.contains(point)
    }

    private func assemble() {
        let outerGlow = SKShapeNode(circleOfRadius: 62)
        outerGlow.fillColor = .clear
        outerGlow.strokeColor = config.palette.teal.withAlphaComponent(0.18)
        outerGlow.lineWidth = 3
        outerGlow.glowWidth = 8
        pad.addChild(outerGlow)
        
        padBase.fillColor = SKColor(hex: 0x061018, alpha: 0.72)
        padBase.strokeColor = config.palette.teal.withAlphaComponent(0.65)
        padBase.lineWidth = 2.5
        padBase.glowWidth = 4
        pad.addChild(padBase)

        let ring = SKShapeNode(circleOfRadius: 22)
        ring.fillColor = .clear
        ring.strokeColor = config.palette.teal.withAlphaComponent(0.25)
        ring.lineWidth = 1.5
        pad.addChild(ring)

        for (vector, rotation) in [
            (CGPoint(x: 0, y: 38), CGFloat(0)),
            (CGPoint(x: 0, y: -38), CGFloat.pi),
            (CGPoint(x: -38, y: 0), CGFloat.pi / 2),
            (CGPoint(x: 38, y: 0), -CGFloat.pi / 2)
        ] {
            let arrow = SKLabelNode(fontNamed: "AvenirNext-Bold")
            arrow.text = "▲"
            arrow.fontSize = 13
            arrow.fontColor = config.palette.teal
            arrow.position = vector
            arrow.zRotation = rotation
            arrow.verticalAlignmentMode = .center
            pad.addChild(arrow)
        }

        padKnob.fillColor = config.palette.teal.withAlphaComponent(0.22)
        padKnob.strokeColor = config.palette.teal
        padKnob.lineWidth = 2
        padKnob.glowWidth = 3
        pad.addChild(padKnob)
        addChild(pad)

        styleButton(shootButton, title: "SHOOT", kind: .shoot, primary: true)
        styleButton(passButton, title: "PASS", kind: .pass, primary: false)
        styleButton(switchButton, title: "SWITCH", kind: .swap, primary: false)
        addChild(shootButton)
        addChild(passButton)
        addChild(switchButton)
    }

    private enum Glyph { case shoot, pass, swap }

    private func styleButton(_ node: SKShapeNode, title: String, kind: Glyph, primary: Bool) {
        node.fillColor = primary 
            ? config.palette.teal.withAlphaComponent(0.15) 
            : SKColor(hex: 0x061018, alpha: 0.72)
        node.strokeColor = config.palette.teal
        node.lineWidth = primary ? 2.5 : 2
        node.glowWidth = primary ? 8 : 4
        node.addChild(glyph(kind, primary: primary))
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        label.text = title
        label.fontSize = primary ? 12 : 10
        label.fontColor = primary ? config.palette.teal : .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: primary ? -20 : -18)
        node.addChild(label)
    }

    private func glyph(_ kind: Glyph, primary: Bool = false) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: 0, y: primary ? 4 : 6)
        switch kind {
        case .shoot:
            let ball = SKShapeNode(circleOfRadius: primary ? 12 : 8)
            ball.fillColor = SKColor(hex: 0xF4F1EA)
            ball.strokeColor = config.palette.teal
            ball.lineWidth = primary ? 2 : 1.2
            ball.glowWidth = primary ? 3 : 0
            root.addChild(ball)
            if primary {
                let arc = SKShapeNode()
                let path = CGMutablePath()
                path.addArc(center: CGPoint(x: 0, y: 18), radius: 12, startAngle: .pi * 0.7, endAngle: .pi * 0.3, clockwise: true)
                arc.path = path
                arc.strokeColor = config.palette.teal.withAlphaComponent(0.6)
                arc.lineWidth = 2
                arc.lineCap = .round
                root.addChild(arc)
            }
        case .pass:
            let ball = SKShapeNode(circleOfRadius: 8)
            ball.fillColor = SKColor(hex: 0xF4F1EA)
            ball.strokeColor = config.palette.teal
            ball.lineWidth = 1.2
            root.addChild(ball)
            let arrow = SKLabelNode(fontNamed: "AvenirNext-Bold")
            arrow.text = "→"
            arrow.fontSize = 12
            arrow.fontColor = config.palette.teal
            arrow.position = CGPoint(x: 14, y: 0)
            arrow.verticalAlignmentMode = .center
            root.addChild(arrow)
        case .swap:
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "⇄"
            label.fontSize = 18
            label.fontColor = config.palette.teal
            label.verticalAlignmentMode = .center
            root.addChild(label)
        }
        return root
    }

    private func press(_ node: SKShapeNode) {
        node.setScale(0.94)
        node.fillColor = config.palette.teal.withAlphaComponent(0.28)
    }

    private func release(_ node: SKShapeNode) {
        node.setScale(1)
        node.fillColor = SKColor(hex: 0x08141C, alpha: 0.58)
        if node === shootButton {
            node.strokeColor = shootLegal ? config.palette.teal.withAlphaComponent(0.9) : SKColor(white: 1, alpha: 0.22)
        } else if node === passButton {
            node.strokeColor = passLegal ? config.palette.teal.withAlphaComponent(0.9) : SKColor(white: 1, alpha: 0.22)
        } else {
            node.strokeColor = config.palette.teal.withAlphaComponent(0.9)
        }
    }

    private func flash(_ node: SKShapeNode) {
        press(node)
        node.run(.sequence([
            .wait(forDuration: 0.08),
            .run { [weak self] in self?.release(node) }
        ]))
    }
    
    private func rejectFlash(_ node: SKShapeNode) {
        node.removeAllActions()
        let originalPosition = node.position
        node.fillColor = config.palette.warning.withAlphaComponent(0.3)
        node.strokeColor = config.palette.warning
        node.run(.sequence([
            .moveBy(x: 4, y: 0, duration: 0.04),
            .moveBy(x: -8, y: 0, duration: 0.04),
            .moveBy(x: 8, y: 0, duration: 0.04),
            .moveBy(x: -4, y: 0, duration: 0.04),
            .run { [weak self, weak node] in
                guard let self, let node else { return }
                node.position = originalPosition
                self.release(node)
            }
        ]))
    }
}
