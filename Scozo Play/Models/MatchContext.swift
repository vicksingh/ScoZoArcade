import CoreGraphics
import Foundation

final class MatchContext {
    var config: GameConfig
    var state: MatchState
    var geometry: CourtGeometry
    var athletes: [PlayerID: Athlete]
    var ball: BallRuntime
    var input: InputSystem
    var rng: SeededGenerator
    var events: [MatchEvent]
    var boardRect: CGRect
    var lastHumanAim: CGVector

    init(config: GameConfig) {
        self.config = config
        self.state = .fresh(config: config)
        self.geometry = .make(config: config)
        self.athletes = [:]
        self.ball = BallRuntime(courtPosition: .zero)
        self.input = InputSystem()
        let seed = config.rngSeed == 0 ? UInt64(Date().timeIntervalSince1970) : config.rngSeed
        self.rng = SeededGenerator(seed: seed)
        self.events = []
        self.boardRect = .zero
        self.lastHumanAim = CGVector(dx: 0, dy: 1)
        resetRosterToFormation()
    }

    func resetRosterToFormation() {
        if athletes.isEmpty {
            for side in TeamSide.allCases {
                for role in PositionRole.allCases {
                    let id = PlayerID(side: side, role: role)
                    let point = role.defaultFormation(in: geometry, team: side)
                    let facing: CGFloat = side == .home ? .pi / 2 : -.pi / 2
                    athletes[id] = Athlete(id: id, courtPosition: point, facing: facing)
                }
            }
        } else {
            for athlete in athletes.values {
                athlete.courtPosition = athlete.id.role.defaultFormation(in: geometry, team: athlete.id.side)
                athlete.velocity = .zero
                athlete.targetPoint = nil
                athlete.facing = athlete.id.side == .home ? .pi / 2 : -.pi / 2
            }
        }
        applyCentrePassPossession()
    }

    func applyCentrePassPossession() {
        let owner = PlayerID(side: state.centrePassSide, role: .c)
        if let centre = athletes[owner] {
            centre.hasBall = true
            ball.attach(to: owner, at: centre.courtPosition)
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
        PositionRole.allCases.compactMap { athletes[PlayerID(side: side, role: $0)] }
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
}
