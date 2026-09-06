import SpriteKit

final class ShootoutResultScene: SKScene {
    private let config: GameConfig
    private let state: ShootoutState
    private let homeClub: Club
    private let awayClub: Club
    
    init(size: CGSize, config: GameConfig, state: ShootoutState, homeClub: Club, awayClub: Club) {
        self.config = config
        self.state = state
        self.homeClub = homeClub
        self.awayClub = awayClub
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
        let winner = state.winner
        let accent = winner == .home ? config.palette.teal : config.palette.magenta
        
        for i in 0..<16 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
            spark.fillColor = i.isMultiple(of: 2) ? config.palette.teal : config.palette.magenta
            spark.strokeColor = .clear
            spark.position = CGPoint(x: w * 0.5, y: h * 0.72)
            addChild(spark)
            let dest = CGPoint(
                x: w * 0.5 + CGFloat.random(in: -100...100),
                y: h * 0.72 + CGFloat.random(in: -50...80)
            )
            spark.run(.sequence([
                .group([
                    .move(to: dest, duration: 0.6),
                    .fadeOut(withDuration: 0.6)
                ]),
                .removeFromParent()
            ]))
        }
        
        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = winner == .home ? "\(homeClub.displayName.uppercased()) WIN!" : (winner == .away ? "\(awayClub.displayName.uppercased()) WIN!" : "TIME UP")
        title.fontSize = 32
        title.fontColor = accent
        title.position = CGPoint(x: w * 0.5, y: h * 0.72)
        addChild(title)
        
        let matchup = SKLabelNode(fontNamed: "AvenirNext-Medium")
        matchup.text = "\(homeClub.displayName) vs \(awayClub.displayName)"
        matchup.fontSize = 14
        matchup.fontColor = SKColor(white: 1, alpha: 0.7)
        matchup.position = CGPoint(x: w * 0.5, y: h * 0.67)
        addChild(matchup)
        
        let scoreRow = SKNode()
        scoreRow.position = CGPoint(x: w * 0.5, y: h * 0.54)
        
        let goalsBox = SKShapeNode(rectOf: CGSize(width: 70, height: 70), cornerRadius: 14)
        goalsBox.fillColor = config.palette.teal.withAlphaComponent(0.9)
        goalsBox.strokeColor = SKColor(white: 1, alpha: 0.2)
        goalsBox.position = CGPoint(x: -50, y: 0)
        scoreRow.addChild(goalsBox)
        
        let goalsNum = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        goalsNum.text = "\(state.homeScore)"
        goalsNum.fontSize = 36
        goalsNum.fontColor = .white
        goalsNum.verticalAlignmentMode = .center
        goalsNum.position = CGPoint(x: -50, y: 4)
        scoreRow.addChild(goalsNum)
        
        let goalsLbl = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        goalsLbl.text = "GOALS"
        goalsLbl.fontSize = 10
        goalsLbl.fontColor = config.palette.arenaDeep
        goalsLbl.position = CGPoint(x: -50, y: -22)
        scoreRow.addChild(goalsLbl)
        
        let vs = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        vs.text = "–"
        vs.fontSize = 30
        vs.fontColor = SKColor(white: 1, alpha: 0.6)
        vs.verticalAlignmentMode = .center
        scoreRow.addChild(vs)
        
        let stopsBox = SKShapeNode(rectOf: CGSize(width: 70, height: 70), cornerRadius: 14)
        stopsBox.fillColor = config.palette.magenta.withAlphaComponent(0.9)
        stopsBox.strokeColor = SKColor(white: 1, alpha: 0.2)
        stopsBox.position = CGPoint(x: 50, y: 0)
        scoreRow.addChild(stopsBox)
        
        let stopsNum = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        stopsNum.text = "\(state.awayStops)"
        stopsNum.fontSize = 36
        stopsNum.fontColor = .white
        stopsNum.verticalAlignmentMode = .center
        stopsNum.position = CGPoint(x: 50, y: 4)
        scoreRow.addChild(stopsNum)
        
        let stopsLbl = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        stopsLbl.text = "STOPS"
        stopsLbl.fontSize = 10
        stopsLbl.fontColor = .white
        stopsLbl.position = CGPoint(x: 50, y: -22)
        scoreRow.addChild(stopsLbl)
        
        addChild(scoreRow)
        
        let summary = SKLabelNode(fontNamed: "AvenirNext-Medium")
        if winner == .home {
            if state.homeScore >= ShootoutState.goalsToWin {
                summary.text = "First to \(ShootoutState.goalsToWin) goals"
            } else {
                summary.text = "Time expired with lead"
            }
        } else if winner == .away {
            if state.awayStops >= ShootoutState.stopsToWin {
                summary.text = "\(ShootoutState.stopsToWin) defensive stops"
            } else {
                summary.text = "Time expired"
            }
        } else {
            summary.text = "Round complete"
        }
        summary.fontSize = 14
        summary.fontColor = SKColor(white: 1, alpha: 0.6)
        summary.position = CGPoint(x: w * 0.5, y: h * 0.40)
        addChild(summary)
        
        let statsLine = SKLabelNode(fontNamed: "AvenirNext-Medium")
        statsLine.text = "Shots: \(state.stats.homeShots)  ·  Passes: \(state.stats.homePasses)  ·  Intercepts: \(state.stats.intercepts)"
        statsLine.fontSize = 11
        statsLine.fontColor = SKColor(white: 1, alpha: 0.45)
        statsLine.position = CGPoint(x: w * 0.5, y: h * 0.35)
        addChild(statsLine)
        
        addButton(title: "REMATCH", name: "rematch", at: CGPoint(x: w * 0.5, y: h * 0.26), fill: accent)
        addButton(title: "MENU", name: "menu", at: CGPoint(x: w * 0.5, y: h * 0.16), fill: SKColor(hex: 0x12202A))
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
            let newAwayClub = Club.random(excluding: homeClub)
            let shootout = ShootoutScene(size: size, config: config, homeClub: homeClub, awayClub: newAwayClub)
            shootout.scaleMode = .resizeFill
            view?.presentScene(shootout, transition: .fade(withDuration: 0.28))
        } else if names.contains("menu") {
            let menu = MenuScene(size: size)
            menu.scaleMode = .resizeFill
            view?.presentScene(menu, transition: .fade(withDuration: 0.28))
        }
    }
}
