import CoreGraphics
import Foundation

final class Athlete {
    let id: PlayerID
    var courtPosition: CGPoint
    var velocity: CGVector
    var facing: CGFloat
    var hasBall: Bool
    var isSelected: Bool
    var isHumanControlled: Bool
    var targetPoint: CGPoint?

    init(
        id: PlayerID,
        courtPosition: CGPoint,
        facing: CGFloat = .pi / 2
    ) {
        self.id = id
        self.courtPosition = courtPosition
        self.velocity = .zero
        self.facing = facing
        self.hasBall = false
        self.isSelected = false
        self.isHumanControlled = false
        self.targetPoint = nil
    }

    var facingVector: CGVector {
        CGVector(dx: cos(facing), dy: sin(facing))
    }
}

enum BallFlightKind: Equatable {
    case none
    case pass
    case shot
    case loose
}

final class BallRuntime {
    var courtPosition: CGPoint
    var owner: PlayerID?
    var flight: BallFlightKind
    var start: CGPoint
    var end: CGPoint
    var elapsed: TimeInterval
    var duration: TimeInterval
    var lift: CGFloat
    var shooter: PlayerID?
    var passerSide: TeamSide?

    init(courtPosition: CGPoint) {
        self.courtPosition = courtPosition
        self.owner = nil
        self.flight = .none
        self.start = courtPosition
        self.end = courtPosition
        self.elapsed = 0
        self.duration = 0
        self.lift = 0
        self.shooter = nil
        self.passerSide = nil
    }

    var isInFlight: Bool {
        flight == .pass || flight == .shot
    }

    func attach(to owner: PlayerID, at point: CGPoint) {
        self.owner = owner
        self.courtPosition = point
        self.flight = .none
        self.elapsed = 0
        self.duration = 0
        self.shooter = nil
        self.passerSide = nil
    }

    func launch(kind: BallFlightKind, from start: CGPoint, to end: CGPoint, duration: TimeInterval, lift: CGFloat, shooter: PlayerID? = nil) {
        self.owner = nil
        self.flight = kind
        self.start = start
        self.end = end
        self.courtPosition = start
        self.elapsed = 0
        self.duration = max(0.12, duration)
        self.lift = lift
        self.shooter = shooter
        self.passerSide = shooter?.side
    }

    func drop(at point: CGPoint) {
        owner = nil
        flight = .loose
        courtPosition = point
        elapsed = 0
        duration = 0
        shooter = nil
        passerSide = nil
    }
}

struct MatchEvent: Equatable {
    enum Kind: Equatable {
        case hint(String)
        case turnover(TeamSide)
        case goal(TeamSide)
        case rebound
        case intercept
        case illegalShoot
    }

    let kind: Kind
}
