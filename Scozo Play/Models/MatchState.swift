import CoreGraphics
import Foundation

enum MatchPhase: String, Equatable {
    case menu
    case centrePass
    case inPlay
    case goalScored
    case quarterBreak
    case overtime
    case matchOver
    case paused
}

struct ShootMeterState: Equatable {
    var value: CGFloat
    var charging: Bool
    var direction: CGFloat
}

struct MatchStats: Equatable {
    var homeShots = 0
    var awayShots = 0
    var homeTurnovers = 0
    var awayTurnovers = 0
    var homePasses = 0
    var awayPasses = 0
}

struct MatchState: Equatable {
    var home: Team
    var away: Team
    var homeScore: Int
    var awayScore: Int
    var quarter: Int
    var quarterCount: Int
    var quarterRemaining: TimeInterval
    var quarterDuration: TimeInterval
    var phase: MatchPhase
    var phaseBeforePause: MatchPhase
    var possessionSide: TeamSide?
    var ballOwner: PlayerID?
    var heldBallElapsed: TimeInterval
    var centrePassSide: TeamSide
    var centrePassTaken: Bool
    var shootMeter: ShootMeterState?
    var winner: TeamSide?
    var resultReason: ResultReason
    var liveViewerCount: Int
    var stats: MatchStats
    var phaseElapsed: TimeInterval
    var overtimeActive: Bool
    var lastGoalToken: Int
    var lastScoringSide: TeamSide?
    var cueMessage: String?

    static func fresh(config: GameConfig) -> MatchState {
        var state = MatchState(
            home: Team(side: .home),
            away: Team(side: .away),
            homeScore: 0,
            awayScore: 0,
            quarter: 1,
            quarterCount: config.quarterCount,
            quarterRemaining: config.quarterDuration,
            quarterDuration: config.quarterDuration,
            phase: .centrePass,
            phaseBeforePause: .centrePass,
            possessionSide: .home,
            ballOwner: PlayerID(side: .home, role: .c),
            heldBallElapsed: 0,
            centrePassSide: .home,
            centrePassTaken: false,
            shootMeter: nil,
            winner: nil,
            resultReason: .none,
            liveViewerCount: config.liveViewerBase,
            stats: MatchStats(),
            phaseElapsed: 0,
            overtimeActive: false,
            lastGoalToken: 0,
            lastScoringSide: nil,
            cueMessage: nil
        )
        state.refreshViewers(config: config)
        return state
    }

    var isFinalQuarter: Bool {
        quarter >= quarterCount && !overtimeActive
    }

    var winningSide: TeamSide? {
        if homeScore == awayScore { return nil }
        return homeScore > awayScore ? .home : .away
    }

    var clockFrozen: Bool {
        switch phase {
        case .inPlay, .overtime: return false
        default: return true
        }
    }

    mutating func resetForNewMatch(config: GameConfig) {
        self = .fresh(config: config)
    }

    mutating func startQuarter(_ number: Int, config: GameConfig, centre: TeamSide) {
        quarter = number
        quarterDuration = overtimeActive ? config.overtimeDuration : config.quarterDuration
        quarterRemaining = quarterDuration
        beginCentrePass(for: centre)
    }

    mutating func beginCentrePass(for side: TeamSide) {
        phase = .centrePass
        phaseElapsed = 0
        centrePassSide = side
        centrePassTaken = false
        possessionSide = side
        ballOwner = PlayerID(side: side, role: .c)
        heldBallElapsed = 0
        shootMeter = nil
        cueMessage = "CENTRE PASS · \(side == .home ? "HOME" : "AWAY")"
    }

    mutating func enterInPlay() {
        phase = overtimeActive ? .overtime : .inPlay
        phaseElapsed = 0
        centrePassTaken = true
        cueMessage = nil
    }

    mutating func awardGoal(to side: TeamSide) -> Bool {
        guard phase == .inPlay || phase == .overtime || phase == .centrePass else { return false }
        lastGoalToken += 1
        lastScoringSide = side
        switch side {
        case .home: homeScore += 1
        case .away: awayScore += 1
        }
        phase = .goalScored
        phaseElapsed = 0
        heldBallElapsed = 0
        shootMeter = nil
        possessionSide = nil
        ballOwner = nil
        cueMessage = "GOAL"
        refreshViewers(config: nil)
        return true
    }

    mutating func endQuarter() {
        phase = .quarterBreak
        phaseElapsed = 0
        shootMeter = nil
        heldBallElapsed = 0
        cueMessage = "END OF Q\(quarter)"
    }

    mutating func pause() {
        guard phase != .paused && phase != .matchOver else { return }
        phaseBeforePause = phase
        phase = .paused
    }

    mutating func resume() {
        guard phase == .paused else { return }
        phase = phaseBeforePause
    }

    mutating func finishMatch(reason: ResultReason) {
        phase = .matchOver
        resultReason = reason
        winner = winningSide
        shootMeter = nil
        if winner == nil {
            resultReason = .draw
        }
        cueMessage = winner == nil ? "DRAW" : "FINAL"
    }

    mutating func resetHeldBall() {
        heldBallElapsed = 0
    }

    mutating func setPossession(owner: PlayerID?) {
        let changed = owner != ballOwner
        ballOwner = owner
        possessionSide = owner?.side
        if changed {
            resetHeldBall()
            shootMeter = nil
        }
    }

    mutating func clearPossession() {
        setPossession(owner: nil)
    }

    mutating func refreshViewers(config: GameConfig?) {
        let base = config?.liveViewerBase ?? liveViewerCount
        liveViewerCount = max(48, base + homeScore * 3 + awayScore * 2 + quarter * 11)
    }

    func formattedClock() -> String {
        let remaining = max(0, quarterRemaining)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func formattedViewers() -> String {
        if liveViewerCount >= 1000 {
            return String(format: "%.1fK", Double(liveViewerCount) / 1000)
        }
        return "\(liveViewerCount)"
    }
}
