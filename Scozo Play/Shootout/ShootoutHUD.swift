import Foundation
import SpriteKit

final class ShootoutHUD: SKNode {
    private let config: GameConfig
    private let scoreCard = SKNode()
    private let goalsLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let stopsLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let clockLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let livePill = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let liveBack = SKShapeNode(rectOf: CGSize(width: 88, height: 22), cornerRadius: 11)
    private let phaseChip = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    private let phaseBack = SKShapeNode(rectOf: CGSize(width: 160, height: 26), cornerRadius: 13)
    private let progressBar = SKNode()
    let pauseButton = SKShapeNode(circleOfRadius: 18)
    
    init(config: GameConfig) {
        self.config = config
        super.init()
        zPosition = ZLayer.hud
        isUserInteractionEnabled = false
        assemble()
    }
    
    required init?(coder: NSCoder) { nil }
    
    func layout(in size: CGSize, safeTop: CGFloat, safeBottom: CGFloat) {
        let top = size.height - safeTop - 10
        scoreCard.position = CGPoint(x: size.width * 0.5, y: top - 40)
        clockLabel.position = CGPoint(x: size.width * 0.5, y: top - 4)
        progressBar.position = CGPoint(x: size.width * 0.5, y: top - 65)
        liveBack.position = CGPoint(x: 58, y: top - 96)
        livePill.position = liveBack.position
        pauseButton.position = CGPoint(x: size.width - 42, y: top - 18)
        let chipY = safeBottom + 40
        phaseBack.position = CGPoint(x: size.width * 0.5, y: chipY)
        phaseChip.position = phaseBack.position
    }
    
    func refresh(_ state: ShootoutState, heldRemaining: TimeInterval?) {
        goalsLabel.text = "\(state.homeScore)"
        stopsLabel.text = "\(state.awayStops)"
        clockLabel.text = state.formattedClock()
        livePill.text = "● LIVE  \(state.liveViewerCount)"
        
        let chip = compactChip(state: state, heldRemaining: heldRemaining)
        if let chip {
            phaseChip.text = chip
            phaseChip.alpha = 1
            phaseBack.alpha = 0.92
        } else {
            phaseChip.alpha = 0
            phaseBack.alpha = 0
        }
        
        updateProgressBar(goals: state.homeScore, stops: state.awayStops)
    }
    
    func hitPause(_ point: CGPoint) -> Bool {
        hypot(point.x - pauseButton.position.x, point.y - pauseButton.position.y) < 26
    }
    
    private func compactChip(state: ShootoutState, heldRemaining: TimeInterval?) -> String? {
        if let heldRemaining, state.ballOwner?.side == .home, heldRemaining <= 1.05, heldRemaining > 0 {
            return "HELD BALL"
        }
        guard let cue = state.cueMessage, !cue.isEmpty else { return nil }
        switch cue {
        case "GOAL!", "INTERCEPTED!", "MISS!", "HELD BALL", "YOU WIN!", "DEFENCE WINS", "TIME UP":
            return cue
        default:
            return nil
        }
    }
    
    private func assemble() {
        let goalsPill = SKShapeNode(rectOf: CGSize(width: 80, height: 36), cornerRadius: 10)
        goalsPill.fillColor = config.palette.teal.withAlphaComponent(0.92)
        goalsPill.strokeColor = SKColor(white: 1, alpha: 0.12)
        goalsPill.lineWidth = 1
        goalsPill.position = CGPoint(x: -52, y: 0)
        scoreCard.addChild(goalsPill)
        
        let goalsTitle = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        goalsTitle.text = "GOALS"
        goalsTitle.fontSize = 9
        goalsTitle.fontColor = config.palette.arenaDeep
        goalsTitle.position = CGPoint(x: -52, y: 10)
        goalsTitle.verticalAlignmentMode = .center
        scoreCard.addChild(goalsTitle)
        
        goalsLabel.fontSize = 22
        goalsLabel.fontColor = .white
        goalsLabel.position = CGPoint(x: -52, y: -6)
        goalsLabel.verticalAlignmentMode = .center
        scoreCard.addChild(goalsLabel)
        
        let stopsPill = SKShapeNode(rectOf: CGSize(width: 80, height: 36), cornerRadius: 10)
        stopsPill.fillColor = config.palette.magenta.withAlphaComponent(0.92)
        stopsPill.strokeColor = SKColor(white: 1, alpha: 0.12)
        stopsPill.lineWidth = 1
        stopsPill.position = CGPoint(x: 52, y: 0)
        scoreCard.addChild(stopsPill)
        
        let stopsTitle = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        stopsTitle.text = "STOPS"
        stopsTitle.fontSize = 9
        stopsTitle.fontColor = .white
        stopsTitle.position = CGPoint(x: 52, y: 10)
        stopsTitle.verticalAlignmentMode = .center
        scoreCard.addChild(stopsTitle)
        
        stopsLabel.fontSize = 22
        stopsLabel.fontColor = .white
        stopsLabel.position = CGPoint(x: 52, y: -6)
        stopsLabel.verticalAlignmentMode = .center
        scoreCard.addChild(stopsLabel)
        
        let vs = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        vs.text = "vs"
        vs.fontSize = 14
        vs.fontColor = SKColor(white: 1, alpha: 0.6)
        vs.position = .zero
        vs.verticalAlignmentMode = .center
        scoreCard.addChild(vs)
        
        addChild(scoreCard)
        
        clockLabel.fontSize = 26
        clockLabel.fontColor = .white
        clockLabel.verticalAlignmentMode = .center
        addChild(clockLabel)
        
        buildProgressBar()
        addChild(progressBar)
        
        liveBack.fillColor = SKColor(hex: 0x061018, alpha: 0.72)
        liveBack.strokeColor = SKColor(hex: 0xE21B70, alpha: 0.45)
        liveBack.lineWidth = 1
        addChild(liveBack)
        livePill.fontSize = 9
        livePill.fontColor = .white
        livePill.verticalAlignmentMode = .center
        addChild(livePill)
        
        phaseBack.fillColor = SKColor(hex: 0x061018, alpha: 0.78)
        phaseBack.strokeColor = config.palette.teal.withAlphaComponent(0.55)
        phaseBack.lineWidth = 1
        phaseBack.alpha = 0
        addChild(phaseBack)
        phaseChip.fontSize = 12
        phaseChip.fontColor = .white
        phaseChip.verticalAlignmentMode = .center
        addChild(phaseChip)
        
        decoratePause()
        addChild(pauseButton)
    }
    
    private func buildProgressBar() {
        let width: CGFloat = 180
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 8), cornerRadius: 4)
        bg.fillColor = SKColor(hex: 0x061018, alpha: 0.78)
        bg.strokeColor = SKColor(white: 1, alpha: 0.15)
        bg.lineWidth = 1
        progressBar.addChild(bg)
        
        for i in 0..<5 {
            let dot = SKShapeNode(circleOfRadius: 3.5)
            dot.fillColor = SKColor(white: 1, alpha: 0.2)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i - 2) * 20 - 50, y: 0)
            dot.name = "goal_\(i)"
            progressBar.addChild(dot)
        }
        
        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: 3.5)
            dot.fillColor = SKColor(white: 1, alpha: 0.2)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i) * 20 + 50, y: 0)
            dot.name = "stop_\(i)"
            progressBar.addChild(dot)
        }
    }
    
    private func updateProgressBar(goals: Int, stops: Int) {
        for i in 0..<5 {
            if let dot = progressBar.childNode(withName: "goal_\(i)") as? SKShapeNode {
                dot.fillColor = i < goals ? config.palette.teal : SKColor(white: 1, alpha: 0.2)
            }
        }
        for i in 0..<3 {
            if let dot = progressBar.childNode(withName: "stop_\(i)") as? SKShapeNode {
                dot.fillColor = i < stops ? config.palette.magenta : SKColor(white: 1, alpha: 0.2)
            }
        }
    }
    
    private func decoratePause() {
        pauseButton.fillColor = SKColor(hex: 0x061018, alpha: 0.55)
        pauseButton.strokeColor = config.palette.teal.withAlphaComponent(0.85)
        pauseButton.lineWidth = 1.5
        pauseButton.glowWidth = 3
        for x in [-4, 4] as [CGFloat] {
            let bar = SKShapeNode(rectOf: CGSize(width: 3.2, height: 12), cornerRadius: 0.8)
            bar.fillColor = config.palette.teal
            bar.strokeColor = .clear
            bar.position = CGPoint(x: x, y: 0)
            pauseButton.addChild(bar)
        }
    }
}
