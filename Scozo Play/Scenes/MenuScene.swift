import SpriteKit

final class MenuScene: SKScene {
    private let config = GameConfig.current
    private var playButton: SKShapeNode?

    override func didMove(to view: SKView) {
        backgroundColor = config.palette.arenaDeep
        removeAllChildren()
        anchorPoint = .zero
        scaleMode = .resizeFill
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

        let glow = SKShapeNode(circleOfRadius: 140)
        glow.fillColor = config.palette.teal.withAlphaComponent(0.12)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: w * 0.5, y: h * 0.62)
        addChild(glow)

        let mag = SKShapeNode(circleOfRadius: 70)
        mag.fillColor = config.palette.magenta.withAlphaComponent(0.16)
        mag.strokeColor = .clear
        mag.position = CGPoint(x: w * 0.72, y: h * 0.48)
        addChild(mag)

        let court = SKShapeNode(rectOf: CGSize(width: 76, height: 120), cornerRadius: 8)
        court.fillColor = config.palette.wood.withAlphaComponent(0.85)
        court.strokeColor = config.palette.cream
        court.lineWidth = 1.4
        court.position = CGPoint(x: w * 0.5, y: h * 0.60)
        court.zRotation = -0.08
        addChild(court)

        let ball = SKShapeNode(circleOfRadius: 8)
        ball.fillColor = SKColor(hex: 0xF3F1EC)
        ball.strokeColor = config.palette.woodDark
        ball.position = CGPoint(x: w * 0.56, y: h * 0.66)
        addChild(ball)

        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = "SCOZO ARCADE"
        title.fontSize = config.titleSize
        title.fontColor = .white
        title.position = CGPoint(x: w * 0.5, y: h * 0.40)
        addChild(title)

        let sub = SKLabelNode(fontNamed: "AvenirNext-Medium")
        sub.text = "5v5 NETBALL · QUICK MATCH"
        sub.fontSize = 13
        sub.fontColor = config.palette.teal
        sub.position = CGPoint(x: w * 0.5, y: h * 0.355)
        addChild(sub)

        let button = SKShapeNode(rectOf: CGSize(width: 188, height: 56), cornerRadius: 16)
        button.fillColor = config.palette.teal
        button.strokeColor = SKColor(white: 1, alpha: 0.35)
        button.position = CGPoint(x: w * 0.5, y: h * 0.24)
        button.name = "play"
        addChild(button)
        playButton = button

        let play = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        play.text = "PLAY"
        play.fontSize = 22
        play.fontColor = config.palette.arenaDeep
        play.verticalAlignmentMode = .center
        play.name = "play"
        button.addChild(play)

        let help = SKLabelNode(fontNamed: "AvenirNext-Medium")
        help.text = "Portrait arcade  ·  four short quarters"
        help.fontSize = 11
        help.fontColor = SKColor(white: 1, alpha: 0.45)
        help.position = CGPoint(x: w * 0.5, y: h * 0.14)
        addChild(help)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if nodes(at: point).contains(where: { $0.name == "play" }) {
            startMatch()
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.key?.charactersIgnoringModifiers == " " || $0.key?.keyCode == .keyboardReturn }) {
            startMatch()
        }
    }

    private func startMatch() {
        let match = MatchScene(size: size, config: config)
        match.scaleMode = .resizeFill
        view?.presentScene(match, transition: .fade(withDuration: 0.35))
    }
}
