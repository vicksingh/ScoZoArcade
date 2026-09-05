import SpriteKit

final class TouchHints: SKNode {
    private let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var shown = false

    override init() {
        super.init()
        zPosition = ZLayer.hints
        label.fontSize = 12
        label.fontColor = SKColor(white: 1, alpha: 0.8)
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 280
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
        alpha = 0
    }

    required init?(coder: NSCoder) { nil }

    func layout(in size: CGSize, safeBottom: CGFloat) {
        position = CGPoint(x: size.width * 0.5, y: safeBottom + 168)
    }

    func showIfNeeded() {
        guard !shown else { return }
        shown = true
        label.text = "D-pad to move  ·  PASS to a teammate\nSHOOT in the circle  ·  no running with the ball"
        alpha = 1
        run(.sequence([
            .wait(forDuration: 4.2),
            .fadeOut(withDuration: 0.6)
        ]))
    }
}

final class OverlayLayer: SKNode {
    private let config: GameConfig
    private let panel = SKShapeNode(rectOf: CGSize(width: 260, height: 220), cornerRadius: 20)
    private let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let body = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let resume = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    var kind: Kind = .hidden

    enum Kind { case hidden, pause, stats }

    init(config: GameConfig) {
        self.config = config
        super.init()
        zPosition = ZLayer.overlays
        isHidden = true
        isUserInteractionEnabled = false

        let dim = SKSpriteNode(color: SKColor(white: 0, alpha: 0.45), size: CGSize(width: 2000, height: 3000))
        dim.zPosition = -1
        addChild(dim)

        panel.fillColor = config.palette.panel
        panel.strokeColor = config.palette.teal
        panel.lineWidth = 1.5
        addChild(panel)

        title.fontSize = 28
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 70)
        addChild(title)

        body.fontSize = 14
        body.fontColor = SKColor(white: 1, alpha: 0.85)
        body.numberOfLines = 6
        body.preferredMaxLayoutWidth = 220
        body.position = CGPoint(x: 0, y: 8)
        body.verticalAlignmentMode = .center
        addChild(body)

        resume.fontSize = 16
        resume.fontColor = config.palette.teal
        resume.text = "TAP TO CLOSE"
        resume.position = CGPoint(x: 0, y: -80)
        addChild(resume)
    }

    required init?(coder: NSCoder) { nil }

    func layout(in size: CGSize) {
        position = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
    }

    func showPause() {
        kind = .pause
        title.text = "PAUSED"
        body.text = "Simulation frozen.\nScore and clock are unchanged."
        isHidden = false
    }

    func showStats(_ state: MatchState) {
        kind = .stats
        title.text = "STATS"
        body.text = """
        \(state.home.displayName)  \(state.homeScore)  –  \(state.awayScore)  \(state.away.displayName)
        Quarter \(state.quarter)   \(state.formattedClock())
        Possession  \(state.possessionSide?.defaultDisplayName ?? "LOOSE")
        Shots  \(state.stats.homeShots)–\(state.stats.awayShots)
        Turnovers  \(state.stats.homeTurnovers)–\(state.stats.awayTurnovers)
        """
        isHidden = false
    }

    func hide() {
        kind = .hidden
        isHidden = true
    }
}
