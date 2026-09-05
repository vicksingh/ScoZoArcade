import Foundation
import SpriteKit

final class HUDNode: SKNode {
    private let config: GameConfig
    private let scoreCard = SKNode()
    private let homeName = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    private let awayName = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    private let homeScore = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let awayScore = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let quarterLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    private let clockLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let livePill = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let liveBack = SKShapeNode(rectOf: CGSize(width: 88, height: 22), cornerRadius: 11)
    private let phaseChip = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    private let phaseBack = SKShapeNode(rectOf: CGSize(width: 148, height: 24), cornerRadius: 12)
    private let quarterDots = SKNode()
    let pauseButton = SKShapeNode(circleOfRadius: 18)
    let statsButton = SKShapeNode(circleOfRadius: 18)

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
        scoreCard.position = CGPoint(x: 14, y: top - 40)
        quarterLabel.position = CGPoint(x: size.width * 0.5, y: top - 4)
        clockLabel.position = CGPoint(x: size.width * 0.5, y: top - 30)
        quarterDots.position = CGPoint(x: size.width * 0.5, y: top - 50)
        liveBack.position = CGPoint(x: 58, y: top - 96)
        livePill.position = liveBack.position
        statsButton.position = CGPoint(x: size.width - 86, y: top - 18)
        pauseButton.position = CGPoint(x: size.width - 42, y: top - 18)
        let chipY = safeBottom + 40
        phaseBack.position = CGPoint(x: size.width * 0.5, y: chipY)
        phaseChip.position = phaseBack.position
        rebuildQuarterDots()
    }

    func refresh(_ state: MatchState, heldRemaining: TimeInterval?) {
        homeName.text = state.home.displayName
        awayName.text = state.away.displayName
        homeScore.text = "\(state.homeScore)"
        awayScore.text = "\(state.awayScore)"
        quarterLabel.text = state.overtimeActive ? "OT" : "Q\(state.quarter)"
        clockLabel.text = state.formattedClock()
        livePill.text = "● LIVE  \(state.formattedViewers())"

        let chip = compactChip(state: state, heldRemaining: heldRemaining)
        if let chip {
            phaseChip.text = chip
            phaseChip.alpha = 1
            phaseBack.alpha = 0.92
        } else {
            phaseChip.alpha = 0
            phaseBack.alpha = 0
        }
        rebuildQuarterDots(current: state.quarter)
    }

    func hitPause(_ point: CGPoint) -> Bool {
        hypot(point.x - pauseButton.position.x, point.y - pauseButton.position.y) < 26
    }

    func hitStats(_ point: CGPoint) -> Bool {
        hypot(point.x - statsButton.position.x, point.y - statsButton.position.y) < 26
    }

    private func compactChip(state: MatchState, heldRemaining: TimeInterval?) -> String? {
        if let heldRemaining,
           heldRemaining <= 1.05,
           heldRemaining > 0,
           state.ballOwner != nil,
           state.possessionSide == .home {
            return "HELD BALL"
        }
        guard let cue = state.cueMessage, !cue.isEmpty else { return nil }
        if cue.hasPrefix("CENTRE PASS") { return "CENTRE PASS" }
        if cue.hasPrefix("END OF") { return cue }
        switch cue {
        case "GOAL", "OVERTIME", "FINAL", "DRAW", "HELD BALL":
            return cue
        default:
            return nil
        }
    }

    private func assemble() {
        addPill(color: config.palette.teal, y: 18, mark: "S")
        addPill(color: config.palette.magenta, y: -16, mark: "N")

        style(homeName, size: 12, color: .white)
        style(awayName, size: 12, color: .white)
        style(homeScore, size: 22, color: .white)
        style(awayScore, size: 22, color: .white)
        homeName.horizontalAlignmentMode = .left
        awayName.horizontalAlignmentMode = .left
        homeScore.horizontalAlignmentMode = .right
        awayScore.horizontalAlignmentMode = .right
        homeName.position = CGPoint(x: 44, y: 18)
        awayName.position = CGPoint(x: 44, y: -16)
        homeScore.position = CGPoint(x: 138, y: 18)
        awayScore.position = CGPoint(x: 138, y: -16)
        scoreCard.addChild(homeName)
        scoreCard.addChild(awayName)
        scoreCard.addChild(homeScore)
        scoreCard.addChild(awayScore)
        addChild(scoreCard)

        style(quarterLabel, size: 15, color: config.palette.teal)
        style(clockLabel, size: 26, color: .white)
        addChild(quarterLabel)
        addChild(clockLabel)
        addChild(quarterDots)

        liveBack.fillColor = SKColor(hex: 0x061018, alpha: 0.72)
        liveBack.strokeColor = SKColor(hex: 0xE21B70, alpha: 0.45)
        liveBack.lineWidth = 1
        addChild(liveBack)
        style(livePill, size: 9, color: .white)
        addChild(livePill)

        phaseBack.fillColor = SKColor(hex: 0x061018, alpha: 0.78)
        phaseBack.strokeColor = config.palette.teal.withAlphaComponent(0.55)
        phaseBack.lineWidth = 1
        phaseBack.alpha = 0
        addChild(phaseBack)
        style(phaseChip, size: 11, color: .white)
        addChild(phaseChip)

        decoratePause()
        decorateStats()
        addChild(statsButton)
        addChild(pauseButton)
    }

    private func addPill(color: SKColor, y: CGFloat, mark: String) {
        let pill = SKShapeNode(rectOf: CGSize(width: 148, height: 30), cornerRadius: 10)
        pill.fillColor = color.withAlphaComponent(0.92)
        pill.strokeColor = SKColor(white: 1, alpha: 0.12)
        pill.lineWidth = 1
        pill.position = CGPoint(x: 74, y: y)
        scoreCard.addChild(pill)
        let badge = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        badge.text = mark
        badge.fontSize = 11
        badge.fontColor = .white
        badge.verticalAlignmentMode = .center
        badge.position = CGPoint(x: 22, y: y)
        scoreCard.addChild(badge)
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

    private func decorateStats() {
        statsButton.fillColor = SKColor(hex: 0x061018, alpha: 0.55)
        statsButton.strokeColor = config.palette.teal.withAlphaComponent(0.85)
        statsButton.lineWidth = 1.5
        statsButton.glowWidth = 3
        for (i, h) in [7, 12, 9].enumerated() {
            let bar = SKShapeNode(rectOf: CGSize(width: 3.4, height: CGFloat(h)), cornerRadius: 0.8)
            bar.fillColor = config.palette.teal
            bar.strokeColor = .clear
            bar.position = CGPoint(x: CGFloat(i - 1) * 6, y: CGFloat(h) * 0.5 - 6)
            statsButton.addChild(bar)
        }
    }

    private func rebuildQuarterDots(current: Int = 1) {
        quarterDots.removeAllChildren()
        for i in 1...4 {
            let dot = SKShapeNode(circleOfRadius: 3.2)
            dot.fillColor = i == current ? config.palette.teal : SKColor(white: 1, alpha: 0.22)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i - 3) * 12 + 6, y: 0)
            quarterDots.addChild(dot)
        }
    }

    private func style(_ label: SKLabelNode, size: CGFloat, color: SKColor) {
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
    }
}
