import SpriteKit

final class ClubPickerScene: SKScene {
    private let config: GameConfig
    private var clubButtons: [SKNode] = []
    private var selectedClub: Club?
    private let lastClub = ClubSelection.shared.lastClub
    
    init(size: CGSize, config: GameConfig) {
        self.config = config
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
        
        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = "CHOOSE YOUR CLUB"
        title.fontSize = 26
        title.fontColor = config.palette.teal
        title.position = CGPoint(x: w * 0.5, y: h * 0.88)
        addChild(title)
        
        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "Adelaide Premier League"
        subtitle.fontSize = 13
        subtitle.fontColor = SKColor(white: 1, alpha: 0.6)
        subtitle.position = CGPoint(x: w * 0.5, y: h * 0.835)
        addChild(subtitle)
        
        let clubs = Club.premierLeague
        let columns = 2
        let rows = 4
        let buttonWidth: CGFloat = 140
        let buttonHeight: CGFloat = 48
        let hGap: CGFloat = 16
        let vGap: CGFloat = 12
        let gridWidth = CGFloat(columns) * buttonWidth + CGFloat(columns - 1) * hGap
        let gridHeight = CGFloat(rows) * buttonHeight + CGFloat(rows - 1) * vGap
        let startX = (w - gridWidth) * 0.5 + buttonWidth * 0.5
        let startY = h * 0.55 + gridHeight * 0.5 - buttonHeight * 0.5
        
        clubButtons.removeAll()
        
        for (index, club) in clubs.enumerated() {
            let col = index % columns
            let row = index / columns
            let x = startX + CGFloat(col) * (buttonWidth + hGap)
            let y = startY - CGFloat(row) * (buttonHeight + vGap)
            
            let isLastPicked = lastClub?.id == club.id
            let button = createClubButton(club: club, highlighted: isLastPicked)
            button.position = CGPoint(x: x, y: y)
            button.name = "club_\(club.id)"
            addChild(button)
            clubButtons.append(button)
            
            if isLastPicked {
                selectedClub = club
            }
        }
        
        let hint = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hint.text = lastClub != nil ? "Tap to change or continue with \(lastClub!.displayName)" : "Tap a club to play"
        hint.fontSize = 11
        hint.fontColor = SKColor(white: 1, alpha: 0.45)
        hint.position = CGPoint(x: w * 0.5, y: h * 0.22)
        addChild(hint)
        
        if lastClub != nil {
            let playButton = SKShapeNode(rectOf: CGSize(width: 188, height: 52), cornerRadius: 16)
            playButton.fillColor = config.palette.teal
            playButton.strokeColor = SKColor(white: 1, alpha: 0.25)
            playButton.position = CGPoint(x: w * 0.5, y: h * 0.12)
            playButton.name = "play"
            addChild(playButton)
            
            let playLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
            playLabel.text = "PLAY"
            playLabel.fontSize = 18
            playLabel.fontColor = .white
            playLabel.verticalAlignmentMode = .center
            playLabel.name = "play"
            playButton.addChild(playLabel)
        }
        
        let backButton = SKLabelNode(fontNamed: "AvenirNext-Medium")
        backButton.text = "← MENU"
        backButton.fontSize = 14
        backButton.fontColor = SKColor(white: 1, alpha: 0.6)
        backButton.position = CGPoint(x: 60, y: h - 50)
        backButton.name = "back"
        addChild(backButton)
    }
    
    private func createClubButton(club: Club, highlighted: Bool) -> SKNode {
        let container = SKNode()
        
        let bg = SKShapeNode(rectOf: CGSize(width: 140, height: 48), cornerRadius: 12)
        bg.fillColor = highlighted 
            ? config.palette.teal.withAlphaComponent(0.25) 
            : SKColor(hex: 0x0A1218, alpha: 0.65)
        bg.strokeColor = highlighted 
            ? config.palette.teal 
            : SKColor(white: 1, alpha: 0.18)
        bg.lineWidth = highlighted ? 2.2 : 1.2
        bg.glowWidth = highlighted ? 4 : 0
        bg.name = "club_\(club.id)"
        container.addChild(bg)
        
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
        label.text = club.displayName.uppercased()
        label.fontSize = 15
        label.fontColor = highlighted ? config.palette.teal : .white
        label.verticalAlignmentMode = .center
        label.name = "club_\(club.id)"
        container.addChild(label)
        
        return container
    }
    
    private func updateSelection(_ club: Club) {
        selectedClub = club
        ClubSelection.shared.save(club)
        
        removeAllChildren()
        build()
    }
    
    private func startShootout(with club: Club) {
        ClubSelection.shared.save(club)
        let aiClub = Club.random(excluding: club)
        let shootout = ShootoutScene(size: size, config: config, homeClub: club, awayClub: aiClub)
        shootout.scaleMode = .resizeFill
        view?.presentScene(shootout, transition: .fade(withDuration: 0.35))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let names = Set(nodes(at: point).compactMap(\.name))
        
        if names.contains("back") {
            let menu = MenuScene(size: size)
            menu.scaleMode = .resizeFill
            view?.presentScene(menu, transition: .fade(withDuration: 0.28))
            return
        }
        
        if names.contains("play"), let club = selectedClub {
            startShootout(with: club)
            return
        }
        
        for name in names {
            if name.hasPrefix("club_") {
                let clubID = String(name.dropFirst(5))
                if let club = Club.find(id: clubID) {
                    if selectedClub?.id == club.id {
                        startShootout(with: club)
                    } else {
                        updateSelection(club)
                    }
                    return
                }
            }
        }
    }
}
