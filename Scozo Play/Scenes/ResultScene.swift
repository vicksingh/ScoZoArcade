import SpriteKit

final class ResultScene: SKScene {
    private let config: GameConfig
    private let match: MatchState

    init(size: CGSize, config: GameConfig, match: MatchState) {
        self.config = config
        self.match = match
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        backgroundColor = config.palette.arenaDeep
        removeAllChildren()
        build()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        removeAllChildren()
        build()
    }

    private func build() {
        let w = size.width
        let h = size.height
        let winner = match.winner
        let accent = winner == .away ? config.palette.magenta : config.palette.teal

        let burst = SKEmitterNode()
        _ = burst
        for i in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            spark.fillColor = i.isMultiple(of: 2) ? config.palette.teal : config.palette.magenta
            spark.strokeColor = .clear
            spark.position = CGPoint(x: w * 0.5, y: h * 0.72)
            addChild(spark)
            let dest = CGPoint(
                x: w * 0.5 + CGFloat.random(in: -90...90),
                y: h * 0.72 + CGFloat.random(in: -40...70)
            )
            spark.run(.sequence([
                .group([
                    .move(to: dest, duration: 0.55),
                    .fadeOut(withDuration: 0.55)
                ]),
                .removeFromParent()
            ]))
        }

        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = match.resultReason == .draw ? "DRAW" : "FINAL"
        title.fontSize = 36
        title.fontColor = accent
        title.position = CGPoint(x: w * 0.5, y: h * 0.72)
        addChild(title)

        let score = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        score.text = "\(match.homeScore)  –  \(match.awayScore)"
        score.fontSize = 48
        score.fontColor = .white
        score.position = CGPoint(x: w * 0.5, y: h * 0.60)
        addChild(score)

        let clubs = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        clubs.text = "\(match.home.displayName)   \(match.away.displayName)"
        clubs.fontSize = 16
        clubs.fontColor = SKColor(white: 1, alpha: 0.7)
        clubs.position = CGPoint(x: w * 0.5, y: h * 0.54)
        addChild(clubs)

        let summary = SKLabelNode(fontNamed: "AvenirNext-Medium")
        if match.resultReason == .draw {
            summary.text = "Level after regulation and overtime"
        } else if let winner {
            let name = winner == .home ? match.home.displayName : match.away.displayName
            let why: String
            switch match.resultReason {
            case .overtime: why = "in overtime"
            case .mercy: why = "mercy rule"
            default: why = "after four quarters"
            }
            summary.text = "\(name) win \(why)"
        } else {
            summary.text = "Four quarters complete"
        }
        summary.fontSize = 13
        summary.fontColor = SKColor(white: 1, alpha: 0.55)
        summary.position = CGPoint(x: w * 0.5, y: h * 0.48)
        addChild(summary)

        addButton(title: "REMATCH", name: "rematch", at: CGPoint(x: w * 0.5, y: h * 0.30), fill: accent)
        addButton(title: "MENU", name: "menu", at: CGPoint(x: w * 0.5, y: h * 0.20), fill: SKColor(hex: 0x12202A))
    }

    private func addButton(title: String, name: String, at point: CGPoint, fill: SKColor) {
        let button = SKShapeNode(rectOf: CGSize(width: 188, height: 52), cornerRadius: 16)
        button.fillColor = fill
        button.strokeColor = SKColor(white: 1, alpha: 0.25)
        button.position = point
        button.name = name
        addChild(button)
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        label.text = title
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        button.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let names = Set(nodes(at: point).compactMap(\.name))
        if names.contains("rematch") {
            let match = MatchScene(size: size, config: config)
            match.scaleMode = .resizeFill
            view?.presentScene(match, transition: .fade(withDuration: 0.28))
        } else if names.contains("menu") {
            let menu = MenuScene(size: size)
            menu.scaleMode = .resizeFill
            view?.presentScene(menu, transition: .fade(withDuration: 0.28))
        }
    }
}
