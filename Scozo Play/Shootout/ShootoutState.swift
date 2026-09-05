import CoreGraphics
import Foundation

enum ShootoutPhase: String, Equatable {
    case ready
    case inPlay
    case goalScored
    case turnover
    case roundOver
    case paused
}

struct ShootoutStats: Equatable {
    var homeGoals = 0
    var awayStops = 0
    var homePasses = 0
    var homeShots = 0
    var intercepts = 0
    var heldBalls = 0
}

struct ShootoutState: Equatable {
    var homeClub: Club
    var awayClub: Club
    var homeScore: Int
    var awayStops: Int
    var clockRemaining: TimeInterval
    var phase: ShootoutPhase
    var phaseBeforePause: ShootoutPhase
    var ballOwner: PlayerID?
    var possessionSide: TeamSide?
    var heldBallElapsed: TimeInterval
    var shootMeter: ShootMeterState?
    var winner: TeamSide?
    var stats: ShootoutStats
    var phaseElapsed: TimeInterval
    var lastGoalToken: Int
    var cueMessage: String?
    var liveViewerCount: Int
    
    static let goalsToWin = 5
    static let stopsToWin = 3
    static let roundDuration: TimeInterval = 90
    
    static func fresh(homeClub: Club, awayClub: Club) -> ShootoutState {
        ShootoutState(
            homeClub: homeClub,
            awayClub: awayClub,
            homeScore: 0,
            awayStops: 0,
            clockRemaining: roundDuration,
            phase: .ready,
            phaseBeforePause: .ready,
            ballOwner: nil,
            possessionSide: .home,
            heldBallElapsed: 0,
            shootMeter: nil,
            winner: nil,
            stats: ShootoutStats(),
            phaseElapsed: 0,
            lastGoalToken: 0,
            cueMessage: nil,
            liveViewerCount: 128
        )
    }
    
    var isRoundOver: Bool {
        phase == .roundOver
    }
    
    var clockFrozen: Bool {
        switch phase {
        case .inPlay: return false
        default: return true
        }
    }
    
    mutating func beginPlay() {
        phase = .inPlay
        phaseElapsed = 0
        cueMessage = nil
    }
    
    mutating func awardGoal() -> Bool {
        guard phase == .inPlay else { return false }
        lastGoalToken += 1
        homeScore += 1
        stats.homeGoals += 1
        phase = .goalScored
        phaseElapsed = 0
        heldBallElapsed = 0
        shootMeter = nil
        ballOwner = nil
        cueMessage = "GOAL!"
        liveViewerCount += 5
        
        if homeScore >= ShootoutState.goalsToWin {
            finishRound(winner: .home)
        }
        return true
    }
    
    mutating func awardStop(reason: String) {
        guard phase == .inPlay else { return }
        awayStops += 1
        stats.awayStops += 1
        phase = .turnover
        phaseElapsed = 0
        heldBallElapsed = 0
        shootMeter = nil
        cueMessage = reason
        
        if awayStops >= ShootoutState.stopsToWin {
            finishRound(winner: .away)
        }
    }
    
    mutating func finishRound(winner: TeamSide?) {
        phase = .roundOver
        self.winner = winner
        shootMeter = nil
        cueMessage = winner == .home ? "YOU WIN!" : (winner == .away ? "DEFENCE WINS" : "TIME UP")
    }
    
    mutating func pause() {
        guard phase != .paused && phase != .roundOver else { return }
        phaseBeforePause = phase
        phase = .paused
    }
    
    mutating func resume() {
        guard phase == .paused else { return }
        phase = phaseBeforePause
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
    
    func formattedClock() -> String {
        let remaining = max(0, clockRemaining)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
