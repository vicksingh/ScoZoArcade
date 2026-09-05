import CoreGraphics
import Foundation

enum TeamSide: String, CaseIterable, Equatable {
    case home
    case away

    var opposing: TeamSide {
        self == .home ? .away : .home
    }

    /// Home attacks toward +Y (far hoop). Away attacks toward -Y (near hoop).
    var attackDirection: CGVector {
        self == .home ? CGVector(dx: 0, dy: 1) : CGVector(dx: 0, dy: -1)
    }

    var defaultDisplayName: String {
        switch self {
        case .home: return "STURT"
        case .away: return "NORWOOD"
        }
    }
}

struct Team: Equatable {
    let side: TeamSide
    var displayName: String
    var roster: [PlayerID]

    init(side: TeamSide, displayName: String? = nil, roster: [PlayerID]? = nil) {
        self.side = side
        self.displayName = displayName ?? side.defaultDisplayName
        self.roster = roster ?? PositionRole.allCases.map { PlayerID(side: side, role: $0) }
    }
}

struct PlayerID: Hashable, Equatable, CustomStringConvertible {
    let side: TeamSide
    let role: PositionRole

    var description: String { "\(side.rawValue)-\(role.rawValue)" }
}

enum ResultReason: Equatable {
    case regulation
    case overtime
    case mercy
    case draw
    case none
}
