import CoreGraphics
import Foundation

final class ShootoutContext {
    var config: GameConfig
    var state: ShootoutState
    var geometry: CourtGeometry
    var athletes: [PlayerID: Athlete]
    var ball: BallRuntime
    var input: InputSystem
    var rng: SeededGenerator
    var events: [MatchEvent]
    var boardRect: CGRect
    var lastHumanAim: CGVector
    var passTargetID: PlayerID?
    
    static let shootoutRoles: [(TeamSide, PositionRole)] = [
        (.home, .gs),
        (.home, .ga),
        (.away, .gk),
        (.away, .gd)
    ]
    
    init(config: GameConfig, homeClub: Club, awayClub: Club) {
        self.config = config
        self.state = .fresh(homeClub: homeClub, awayClub: awayClub)
        self.geometry = .make(config: config)
        self.athletes = [:]
        self.ball = BallRuntime(courtPosition: .zero)
        self.input = InputSystem()
        let seed = config.rngSeed == 0 ? UInt64(Date().timeIntervalSince1970) : config.rngSeed
        self.rng = SeededGenerator(seed: seed)
        self.events = []
        self.boardRect = .zero
        self.lastHumanAim = CGVector(dx: 0, dy: 1)
        resetRoster()
    }
    
    func resetRoster() {
        if athletes.isEmpty {
            for (side, role) in Self.shootoutRoles {
                let id = PlayerID(side: side, role: role)
                let point = shootoutSpawn(role: role, team: side)
                let facing: CGFloat = side == .home ? .pi / 2 : -.pi / 2
                athletes[id] = Athlete(id: id, courtPosition: point, facing: facing)
            }
        } else {
            for athlete in athletes.values {
                athlete.courtPosition = shootoutSpawn(role: athlete.id.role, team: athlete.id.side)
                athlete.velocity = .zero
                athlete.targetPoint = nil
                athlete.facing = athlete.id.side == .home ? .pi / 2 : -.pi / 2
                athlete.hasBall = false
            }
        }
        applyInitialPossession()
    }
    
    private func shootoutSpawn(role: PositionRole, team: TeamSide) -> CGPoint {
        let cx = geometry.midX
        let circleY = geometry.shootingCircleCenter(for: .home).y
        let radius = geometry.shootingCircleRadius
        
        switch (team, role) {
        case (.home, .gs):
            return CGPoint(x: cx - 35, y: circleY - radius * 0.4)
        case (.home, .ga):
            return CGPoint(x: cx + 40, y: circleY - radius * 0.65)
        case (.away, .gk):
            return CGPoint(x: cx + 10, y: circleY + radius * 0.25)
        case (.away, .gd):
            return CGPoint(x: cx - 30, y: circleY - radius * 0.15)
        default:
            return CGPoint(x: cx, y: circleY)
        }
    }
    
    func applyInitialPossession() {
        let owner = PlayerID(side: .home, role: .gs)
        if let gs = athletes[owner] {
            gs.hasBall = true
            ball.attach(to: owner, at: gs.courtPosition)
        }
        state.setPossession(owner: owner)
        for athlete in athletes.values {
            athlete.hasBall = athlete.id == owner
        }
    }
    
    func athlete(_ id: PlayerID) -> Athlete? {
        athletes[id]
    }
    
    func roster(for side: TeamSide) -> [Athlete] {
        Self.shootoutRoles
            .filter { $0.0 == side }
            .compactMap { athletes[PlayerID(side: $0.0, role: $0.1)] }
    }
    
    func selectedHome() -> Athlete? {
        roster(for: .home).first(where: { $0.isSelected }) ?? roster(for: .home).first
    }
    
    func carrier() -> Athlete? {
        guard let owner = state.ballOwner else { return nil }
        return athletes[owner]
    }
    
    func nearest(to point: CGPoint, side: TeamSide?, excluding: PlayerID? = nil) -> Athlete? {
        athletes.values
            .filter { athlete in
                if let excluding, athlete.id == excluding { return false }
                if let side, athlete.id.side != side { return false }
                return true
            }
            .min { a, b in
                hypot(a.courtPosition.x - point.x, a.courtPosition.y - point.y)
                    < hypot(b.courtPosition.x - point.x, b.courtPosition.y - point.y)
            }
    }
    
    func displayPoint(_ court: CGPoint) -> CGPoint {
        geometry.displayPoint(fromCourt: court, in: boardRect)
    }
    
    func courtPoint(_ display: CGPoint) -> CGPoint {
        geometry.courtPoint(fromDisplay: display, in: boardRect)
    }
    
    func random01() -> CGFloat {
        CGFloat(rng.next() % 10_000) / 10_000
    }
    
    func emit(_ kind: MatchEvent.Kind) {
        events.append(MatchEvent(kind: kind))
        if case .hint(let text) = kind {
            state.cueMessage = text
        }
    }
    
    func otherAttacker(from current: PlayerID) -> Athlete? {
        roster(for: .home).first { $0.id != current }
    }
    
    func shootoutZone(for role: PositionRole, team: TeamSide) -> CGRect {
        let circleCenter = geometry.shootingCircleCenter(for: .home)
        let radius = geometry.shootingCircleRadius
        let apron: CGFloat = 45
        
        switch (team, role) {
        case (.home, .gs), (.home, .ga):
            return CGRect(
                x: circleCenter.x - radius - apron,
                y: circleCenter.y - radius - apron,
                width: (radius + apron) * 2,
                height: (radius + apron) * 2
            ).intersection(geometry.bounds)
        case (.away, .gk), (.away, .gd):
            return CGRect(
                x: circleCenter.x - radius - 10,
                y: circleCenter.y - radius - 10,
                width: (radius + 10) * 2,
                height: (radius + 10) * 2
            ).intersection(geometry.bounds)
        default:
            return geometry.bounds
        }
    }
}
