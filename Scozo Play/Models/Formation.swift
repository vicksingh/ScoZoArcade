import CoreGraphics

/// Court-local 5v5 spawns. Origin is bottom-left; home attacks +Y (top hoop).
enum Formation {
    static func spawn(role: PositionRole, team: TeamSide, in geometry: CourtGeometry) -> CGPoint {
        let n = normalized(role: role, team: team)
        return CGPoint(x: n.x * geometry.size.width, y: n.y * geometry.size.height)
    }

    /// Normalized 0...1 slots. Centres sit just outside the centre circle on opposite sides.
    /// Attack-end GS is offset opposite the defending GK so they never share a pixel.
    private static func normalized(role: PositionRole, team: TeamSide) -> CGPoint {
        switch (team, role) {
        case (.home, .gk): return CGPoint(x: 0.28, y: 0.08)
        case (.home, .gd): return CGPoint(x: 0.74, y: 0.21)
        case (.home, .c):  return CGPoint(x: 0.30, y: 0.46)
        case (.home, .ga): return CGPoint(x: 0.22, y: 0.68)
        case (.home, .gs): return CGPoint(x: 0.38, y: 0.83)
        case (.away, .gk): return CGPoint(x: 0.72, y: 0.92)
        case (.away, .gd): return CGPoint(x: 0.22, y: 0.79)
        case (.away, .c):  return CGPoint(x: 0.70, y: 0.54)
        case (.away, .ga): return CGPoint(x: 0.78, y: 0.32)
        case (.away, .gs): return CGPoint(x: 0.60, y: 0.15)
        }
    }

    static func allSpawns(in geometry: CourtGeometry) -> [(PlayerID, CGPoint)] {
        var result: [(PlayerID, CGPoint)] = []
        for team in TeamSide.allCases {
            for role in PositionRole.allCases {
                let id = PlayerID(side: team, role: role)
                result.append((id, spawn(role: role, team: team, in: geometry)))
            }
        }
        return result
    }

    static func minimumSeparation(playerRadius: CGFloat) -> CGFloat {
        4 * playerRadius
    }

    static func isSeparated(in geometry: CourtGeometry, playerRadius: CGFloat) -> Bool {
        let points = allSpawns(in: geometry).map(\.1)
        let limit = minimumSeparation(playerRadius: playerRadius)
        for i in 0..<points.count {
            for j in (i + 1)..<points.count {
                let dx = points[i].x - points[j].x
                let dy = points[i].y - points[j].y
                if hypot(dx, dy) < limit { return false }
            }
        }
        return true
    }
}
